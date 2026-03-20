# Flutter 무지개 붓 성능 최적화 여정

> Flutter CustomPainter에서 그라디언트 선을 그릴 때 발생하는 성능 저하를 단계적으로 해결한 기록입니다.

---

## 배경

유아용 그림 그리기 앱(Flutter, Android/iOS)에서 무지개 붓 도구를 만들었습니다.
무지개 붓은 손가락이 움직이는 방향을 따라 색상이 순환하는 선을 그립니다.

**증상**: 처음 3~5초는 부드럽게 그려지지만, 선이 길어질수록 급격히 느려져 3초 이상 연속 드로잉이 어려웠습니다. 웹(Chrome)에서는 문제가 없었고, Android APK에서만 발생했습니다.

---

## 1단계 — 초기 구현: O(N) 드로콜

### 구조

무지개 선은 색상이 연속적으로 변하기 때문에 단일 `drawLine`으로는 표현이 불가능합니다.
초기 구현은 포인트 두 개를 한 세그먼트로 보고, 각 세그먼트마다 그라디언트 선을 그렸습니다.

```dart
for (int i = 0; i < stroke.points.length - 1; i++) {
  final p0 = stroke.points[i];
  final p1 = stroke.points[i + 1];

  final paint = Paint()
    ..strokeWidth = stroke.size
    ..shader = ui.Gradient.linear(p0, p1, [colors[i], colors[i + 1]]);

  canvas.drawLine(p0, p1, paint);
}
```

### 문제

| 항목 | 비용 |
|------|------|
| `ui.Gradient.linear()` 생성 | 세그먼트 수 N번 |
| `canvas.drawLine()` 호출 | 세그먼트 수 N번 |
| GPU draw call | N번 |

손가락을 오래 움직일수록 포인트가 쌓이고, **매 프레임 N번의 GPU 드로콜**이 발생합니다.
60fps 기준 1초에 ~60프레임 × N세그먼트 = 선이 길수록 기하급수적으로 무거워집니다.

---

## 2단계 — 1차 시도: PictureRecorder 누적 캐시 (실패)

### 아이디어

`ui.PictureRecorder`로 완성된 세그먼트를 누적해두고, 매 프레임 전체를 다시 그리는 대신 이전 Picture에 새 세그먼트만 추가하면 O(1)이 될 것이라 생각했습니다.

```dart
// 매 addPoint 시:
final recorder = ui.PictureRecorder();
final c = Canvas(recorder);

// 기존 Picture 재생
c.drawPicture(_rainbowPicture!);   // ← 이전 프레임 Picture

// 새 세그먼트만 추가
c.drawLine(p0, p1, segPaint);

_rainbowPicture = recorder.endRecording();
```

### 왜 실패했나

이 방식은 Picture가 **체인처럼 중첩**됩니다.

```
Frame 1: Picture₁ = { drawLine(seg0) }
Frame 2: Picture₂ = { drawPicture(Picture₁), drawLine(seg1) }
Frame 3: Picture₃ = { drawPicture(Picture₂), drawLine(seg2) }
...
Frame N: PictureN = { drawPicture(PictureN₋₁), drawLine(segN) }
```

`canvas.drawPicture(PictureN)`을 GPU가 재생할 때 중첩 체인을 재귀적으로 순회합니다.
→ 여전히 **O(N) GPU 작업**, CPU recording만 줄어든 것.

---

## 3단계 — 2차 시도: saveLayer 최적화 + _completedPicture 캐시 (부분 성공)

### 문제 분석

`saveLayer`가 전체 캔버스 크기의 오프스크린 버퍼를 매 프레임 생성하고, 그 안에서 `_rainbowPicture`가 재생되는 구조였습니다.

```dart
// Before
canvas.saveLayer(rect, Paint());         // ← 전체 크기 오프스크린 버퍼
  canvas.drawPicture(completedPicture);  // ← 완성 strokes
  canvas.drawPicture(rainbowPicture);    // ← 현재 stroke
canvas.restore();
```

GPU는 `saveLayer` 내부의 Picture를 텍스처로 캐시하지 못하기 때문에,
완성된 strokes가 많아질수록 매 프레임 모두 재렌더됩니다.

### 적용한 개선

**① 완성된 strokes를 saveLayer 밖으로 이동**

```dart
// After
canvas.drawPicture(completedPicture);   // ← saveLayer 밖: GPU 텍스처 캐시 가능

canvas.saveLayer(rect, Paint());        // ← 현재 stroke에만 적용
  canvas.drawPicture(rainbowPicture);
canvas.restore();
```

**② TraceCanvas에 `_completedPicture` 캐시 추가**
TraceCanvas는 매 프레임 모든 완성 strokes를 `drawElement()`로 재렌더하고 있었습니다.
DrawingCanvas와 동일하게 `ui.PictureRecorder`로 완성 strokes를 굽는 방식을 적용했습니다.

**③ HitZone.buildClipPath() lazy 캐시**
선 따라 그리기 화면에서 매 프레임 수백 개의 원으로 클리핑 Path를 재생성하고 있었습니다.
getter lazy 캐시로 변환해 최초 1회만 생성하도록 수정했습니다.

### 결과

완성된 strokes의 성능은 개선됐지만, **현재 그리는 중인 무지개 stroke의 느려짐 문제는 미해결**.
Picture 중첩 체인 문제가 여전히 존재했습니다.

---

## 4단계 — 3차 시도: toImageSync 체크포인트 (부분 성공)

### 아이디어

`ui.Picture.toImageSync()`는 Flutter 3.7+에서 동기적으로 Picture를 GPU 텍스처(`ui.Image`)로 변환합니다.
N번 중첩된 Picture 체인을 flat한 GPU 텍스처 1장으로 **평탄화**할 수 있습니다.

```
매 30 세그먼트마다:
  PictureRecorder → Picture → toImageSync() → ui.Image (GPU 텍스처)

매 프레임:
  canvas.drawImage(_rainbowImage)    // O(1) GPU 텍스처 blit
  pending 세그먼트 최대 29개 렌더    // O(K), K ≤ 29
```

### 구현

```dart
void _buildCheckpoint(RainbowStroke stroke, int upToSeg) {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);

  if (_rainbowImage != null) {
    c.drawImage(_rainbowImage!, Offset.zero, Paint());
  }

  // 새 세그먼트들 추가
  for (int i = _checkpointSegCount; i < upToSeg; i++) {
    // ... drawLine
  }

  final picture = recorder.endRecording();
  _rainbowImage = picture.toImageSync(width, height); // GPU 텍스처로 평탄화
  picture.dispose();
  _checkpointSegCount = upToSeg;
}
```

### 한계

체크포인트 사이(최대 29프레임) 동안은 pending 세그먼트를 여전히 `drawLine` N번으로 그렸습니다.
또한 `drawLine + Gradient.linear` 방식 자체가 GPU에 부담이 컸습니다.

---

## 5단계 — 4차 시도: drawVertices triangle strip (성공)

### 핵심 인사이트

`drawLine` + `Gradient.linear`의 근본 문제는 **"세그먼트 하나 = GPU draw call 하나"**라는 구조입니다.
`canvas.drawVertices()`를 사용하면 수백 개의 세그먼트를 **단 1번의 GPU draw call**로 처리할 수 있습니다.

### 원리

각 선분을 두께가 있는 사각형(쿼드, 삼각형 2개)으로 변환하고, 각 꼭짓점에 색상을 지정합니다.
GPU가 삼각형 내부를 per-vertex 컬러로 선형 보간(interpolate)하여 그라디언트를 생성합니다.

```
선분 p0→p1 (색상 c0→c1):

     p0+perp(c0) ─────── p1+perp(c1)
          │    ╲           │
          │      ╲ tri 2   │
          │  tri 1 ╲       │
     p0-perp(c0) ─────── p1-perp(c1)
```

- `perp` = 진행 방향의 수직 벡터 × (선 두께 / 2)
- 두 삼각형의 꼭짓점 색상 = 해당 포인트의 무지개 색
- GPU 보간 결과 = `Gradient.linear`와 시각적으로 동일

### 구현

```dart
void drawRainbowSegmentRange(
    Canvas canvas, RainbowStroke stroke, int fromSeg, int toSeg) {
  final halfWidth = stroke.size / 2;
  final positions = <Offset>[];
  final colors = <Color>[];
  final indices = <int>[];
  int vi = 0;

  for (int i = fromSeg; i < toSeg; i++) {
    final p0 = stroke.points[i];
    final p1 = stroke.points[i + 1];
    if ((p1 - p0).distance < 0.5) continue;

    final c0 = stroke.colors[i];
    final c1 = stroke.colors[i + 1];

    // 수직 벡터로 선분 → 사각형 확장
    final d = p1 - p0;
    final perp = Offset(-d.dy, d.dx) / d.distance * halfWidth;

    positions.addAll([p0 + perp, p0 - perp, p1 + perp, p1 - perp]);
    colors.addAll([c0, c0, c1, c1]);
    indices.addAll([vi, vi+1, vi+2, vi+1, vi+3, vi+2]);  // 삼각형 2개
    vi += 4;
  }

  if (positions.isEmpty) return;

  // ← 핵심: N개 세그먼트를 GPU draw call 1번으로 처리
  canvas.drawVertices(
    ui.Vertices(ui.VertexMode.triangles, positions,
        colors: colors, indices: indices),
    BlendMode.srcOver,
    Paint()..isAntiAlias = true,
  );
}
```

### 동시에 적용한 추가 최적화

**① saveLayer 제거 (non-blur rainbow)**

무지개 붓은 `BlendMode.clear`(지우개)를 사용하지 않으므로 `saveLayer`가 불필요합니다.

```dart
// Before: 항상 saveLayer
canvas.saveLayer(rect, Paint());
drawRainbow(canvas, current);
canvas.restore();

// After: blur 없으면 saveLayer 제거
if (current.blurSigma > 0) {
  canvas.saveLayer(rect,
      Paint()..imageFilter = ui.ImageFilter.blur(
          sigmaX: blurSigma, sigmaY: blurSigma));
}
drawRainbow(canvas, current);
if (current.blurSigma > 0) canvas.restore();
```

**② blur 처리 방식 변경**

기존: 세그먼트마다 `MaskFilter.blur` → N번 blur 연산
변경: 전체 stroke 레이어에 `ImageFilter.blur` 1회 적용

시각적 차이: 기존은 세그먼트별 halo가 겹쳐 더 두꺼운 glow를 만들었고, 변경 후는 stroke 전체에 균일한 glow가 적용됩니다. 유아 앱 특성상 오히려 더 깔끔한 결과입니다.

**③ 체크포인트 간격 축소: 30 → 10**

pending 세그먼트 최대치를 29개 → 9개로 줄여 체크포인트 사이의 drawVertices 비용을 최소화합니다.

---

## 성능 비교

| 구현 방식 | GPU draw call | CPU 부담 | 결과 |
|-----------|--------------|---------|------|
| 초기 (drawLine×N) | O(N) | O(N) | ❌ 3초 후 버벅 |
| PictureRecorder 체인 | O(N) 재귀 | O(1) | ❌ 동일 증상 |
| saveLayer + completedPicture | O(N) 유지 | 완성 stroke O(1) | △ 부분 개선 |
| toImageSync 체크포인트 | O(K), K≤29 | O(K) | △ 개선됐으나 미흡 |
| **drawVertices (최종)** | **O(1)** | **O(K), K≤9** | **✅ 완전 해결** |

---

## 핵심 교훈

### 1. `drawLine × N`은 그라디언트 선의 안티패턴

Flutter `Canvas`에서 `drawLine`을 N번 호출하는 것은 N번의 GPU draw call을 의미합니다.
색이 변하는 선을 그릴 때는 처음부터 `drawVertices`로 설계하는 것이 올바른 접근입니다.

### 2. `ui.Picture` 중첩 체인은 O(N) 재귀

`drawPicture(이전Picture)` 패턴으로 누적하면 CPU recording은 O(1)이지만,
GPU replay 시 중첩 깊이만큼 재귀 순회가 발생합니다.
진정한 O(1)을 원한다면 `toImageSync()`로 주기적으로 GPU 텍스처에 평탄화해야 합니다.

### 3. `saveLayer`는 GPU 텍스처 캐시를 막는다

완성된 stroke처럼 변하지 않는 콘텐츠는 `saveLayer` 밖에서 그려야 GPU가 텍스처를 캐시합니다.
`saveLayer`는 지우개(`BlendMode.clear`)처럼 반드시 필요한 경우에만 사용해야 합니다.

### 4. 성능 vs 품질 트레이드오프 주의

`drawVertices`는 joint(꺾임) 처리가 없어 날카로운 코너에서 미세한 틈이 생길 수 있습니다.
유아 앱처럼 부드러운 드로잉이 주가 되는 경우 실용적으로 무시할 수 있는 수준이지만,
각진 획이 많은 앱이라면 joint 처리를 별도로 구현해야 합니다.

---

## 참고 자료

- [Flutter Canvas.drawVertices API](https://api.flutter.dev/flutter/dart-ui/Canvas/drawVertices.html)
- [Flutter raster thread performance optimization](https://medium.com/flutter/raster-thread-performance-optimization-tips-e949b9dbcf06)
- [Flutter FragmentShader 공식 문서](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)
- [Flutter Issue #23461 — Canvas drawing performance](https://github.com/flutter/flutter/issues/23461)
- [High-Performance Canvas Rendering — plugfox.dev](https://plugfox.dev/high-performance-canvas-rendering/)
