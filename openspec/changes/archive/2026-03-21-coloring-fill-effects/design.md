## Context

toktok-drawing는 Flutter + Riverpod 기반의 3~7세 유아용 그림 앱이다. 현재 free_drawing, trace_drawing, symmetry_drawing 등의 모드가 있으며, `CustomPaint` + `GestureDetector` 패턴과 Riverpod Provider로 상태 관리를 일관되게 사용한다. `assets/templates/coloring/` 디렉토리가 pubspec.yaml에 이미 등록되어 있어 색칠 템플릿 에셋 수용이 준비된 상태다.

`character.svg`는 Adobe Illustrator로 제작된 SVG로, `<path>` 요소 220개, fill 색상 5종(`#2EA3AE`, `#21808A`, `#E6A032`, `#E6A3A1`, `#2A2727`)으로 구성된다. `flutter_svg` 패키지가 이미 포함되어 있으나, 개별 path 단위 인터랙션을 위해서는 SVG를 Flutter `Path` 객체 배열로 직접 파싱해야 한다.

## Goals / Non-Goals

**Goals:**
- SVG의 각 `<path>`를 Flutter `Path`로 파싱하여 흰색 단면 + 검정 테두리로 렌더링
- 탭 지점의 path 인식 (hit detection)
- 4가지 마법 채우기 애니메이션: Sparkle / Pattern / Paint Flood / Pencil
- 모든 단면 완성 시 축하 연출

**Non-Goals:**
- 사용자가 직접 색상을 선택하는 기능 (SVG에 정의된 색상만 사용)
- 색칠 결과물 저장/갤러리 연동 (초기 릴리즈에서 제외)
- 다수의 SVG 캐릭터 선택 기능 (character.svg 단일 파일)
- 실행 취소(undo) 기능

## Decisions

### 결정 1: SVG path 파싱 방식 — `xml` 패키지 + `path_parsing`

**채택**: pubspec.yaml에 `xml` 패키지를 추가하여 SVG XML을 DOM으로 파싱하고, `flutter_svg`의 전이 의존성인 `path_parsing` 패키지의 `parseSvgPathData()`로 path `d` 속성을 Flutter `Path` 객체로 변환한다.

```
SvgPathData (String) → path_parsing.parseSvgPathData() → ui.Path
```

**대안 A: `flutter_svg`의 렌더링 결과 위에 투명 오버레이 배치**
SVG를 그대로 보여주고, 각 path 좌표를 계산해 `GestureDetector`를 오버레이하는 방식. path가 단순 사각형이 아닌 복잡한 곡선이므로 정확한 탭 감지가 불가능하다. 기각.

**대안 B: 오프스크린 렌더링 후 픽셀 색상 읽기 (Color Picking)**
각 path를 고유 색상으로 오프스크린 렌더링하고, 탭 지점의 픽셀 색상으로 path를 식별하는 방식. 정확하지만 매 탭마다 렌더링 + GPU readback이 필요해 느리다. 기각.

**선택 이유**: `path_parsing`은 `flutter_svg`의 전이 의존성이므로 추가 패키지 비용 없이 사용 가능. `ui.Path.contains()`로 O(n) hit detection이 220개 path에 대해 충분히 빠르다.

---

### 결정 2: 채우기 애니메이션 클리핑 — `Canvas.clipPath()`

탭된 path의 클리핑 영역 안에서 애니메이션을 그린다. `canvas.save()` → `canvas.clipPath(targetPath)` → 애니메이션 그리기 → `canvas.restore()`. 이렇게 하면 애니메이션이 path 경계를 절대 벗어나지 않아 각 효과 구현이 단순해진다.

---

### 결정 3: 4가지 애니메이션 구현 전략

**Sparkle Fill (마법가루)**
- 파티클 N개(50~100)를 path bounding box 내 랜덤 위치에 생성. path 외부 파티클은 clipPath가 자동 제거.
- 각 파티클: 0→최종크기(scale-up, 200ms), 깜빡임(opacity oscillation), 최종 색상 fade-in.
- 애니메이션 후반부(600ms~900ms)에 solid fill이 fade-in되며 파티클과 합성.
- 기존 sparkle-brush 파티클 모델(`star`, `heart`, `circle`) 재사용.

**Pattern Fill (패턴 솟기)**
- path bounding box를 격자(grid)로 나눠 각 셀 중심에 귀여운 도형(별, 하트, 점) 배치.
- 탭 지점에서 가까운 셀부터 순차적으로 scale-up (ripple 순서, delay 증가).
- 모든 셀 등장 후 도형들이 solid fill로 합쳐지는 효과.

**Paint Flood Fill (물감 번짐)**
- 탭 지점에서 원을 시작해 반경을 path 대각선 길이만큼 확장 (RadialGradient 또는 expandable circle).
- `canvas.drawCircle(tapOffset, radius * t, paint)` — `t`를 0→1로 애니메이션.
- clipPath가 path 경계를 자동 처리하므로 구현이 단순.
- 색상은 SVG 원본 fill color, 약간의 불투명도 변화로 물감 느낌 추가.

**Pencil Fill (색연필)**
- path bounding box 내에 랜덤 방향의 짧은 선분들(strokes)을 시간에 따라 누적 그리기.
- 기존 `pencil.frag` GLSL 셰이더를 `FragmentProgram`으로 로드하여 각 선에 적용.
- 선 밀도가 증가하면서 점점 단면이 채워지는 느낌. 완료 시 solid fill overlay.

---

### 결정 4: 상태 관리 — Riverpod `StateNotifier`

```
ColoringProvider (StateNotifier<ColoringState>)
  - parsedPaths: List<ColoringPath>  // SVG 파싱 결과
  - filledPaths: Set<int>            // 채워진 path 인덱스
  - activeAnimation: ColoringAnimation?  // 현재 진행 중인 애니메이션
```

`ColoringPath` = `{ path: ui.Path, fillColor: Color, bounds: Rect }`

애니메이션은 `ColoringCanvas` 위젯의 `State`에서 `AnimationController`로 관리 (1개 동시 진행). 애니메이션 완료 → provider의 `filledPaths`에 추가 → 위젯이 solid fill로 리렌더.

---

### 결정 5: SVG transform 처리 — 캔버스 스케일 매핑

character.svg의 viewBox는 `0 0 630 648`. 디바이스 캔버스 크기에 맞게 uniform scale 적용.

```dart
final scale = min(canvasSize.width / 630, canvasSize.height / 648);
final dx = (canvasSize.width - 630 * scale) / 2;
final dy = (canvasSize.height - 648 * scale) / 2;
final matrix = Matrix4.identity()..translate(dx, dy)..scale(scale);
```

hit detection 시 탭 좌표를 역변환(`matrix.inverted()`)하여 SVG 좌표계에서 `path.contains()` 호출.

---

### 결정 6: 완성 축하 연출 — 전체 화면 Sparkle 오버레이

모든 path가 채워지면 ColoringProvider가 completion 이벤트를 발행. `ColoringScreen`에서 `OverlayEntry`로 전체 화면 Sparkle 파티클 애니메이션 표시 (2초), 이후 결과 화면 또는 모드 선택으로 복귀.

## Risks / Trade-offs

**[Risk] path_parsing이 이 SVG의 path 데이터를 완전히 지원하지 않을 수 있음**
→ Mitigation: character.svg로 파싱 단위 테스트를 먼저 작성. 실패 path는 bounding box rect로 fallback.

**[Risk] 220개 path에 대한 `contains()` hit detection이 복잡한 곡선 path에서 느릴 수 있음**
→ Mitigation: 먼저 bounding box `Rect.contains()`로 후보를 좁힌 후 `Path.contains()` 호출. 실측 성능이 16ms를 초과하면 isolate로 분리.

**[Risk] `path_parsing`은 내부 API이므로 flutter_svg 버전 업 시 깨질 수 있음**
→ Mitigation: pubspec.yaml에 flutter_svg 버전을 pin(`^2.0.16`). 장기적으로는 자체 파서로 교체 검토.

**[Trade-off] Pencil Fill에 셰이더 사용 시 일부 구형 기기에서 미지원**
→ Fallback: 셰이더 로드 실패 시 일반 `Paint`로 선분 그리기.

**[Trade-off] 4가지 애니메이션 중 1개만 동시 재생**
→ 애니메이션 진행 중에는 다른 단면 탭 입력을 무시(block). 현재 애니메이션이 완전히 종료된 후에만 다음 탭이 처리된다. 아이들이 효과를 온전히 감상하도록 유도하는 의도적 제약이지만, 테스트 후 UX에 따라 변경될 수 있음.

## Migration Plan

1. `assets/templates/coloring/character.svg`에 파일 복사 (character.svg → coloring 템플릿으로 분류)
2. `lib/features/coloring/` 신규 모듈 구현 (기존 코드 수정 없이 추가)
3. `lib/features/mode_selection/` 에 색칠하기 진입 버튼 추가
4. 기존 모드 동작 영향 없음 (독립 모듈)

롤백: mode_selection에서 버튼만 제거하면 기능 비활성화. 기존 코드 변경이 최소이므로 리스크 낮음.

## Open Questions

1. **애니메이션 선택 방식**: 4가지 효과를 랜덤 적용할지, 탭할 때마다 순환할지, 사용자가 선택할지? → 초기 구현은 랜덤 적용 후 사용자 피드백 반영.
2. **path 식별 우선순위**: 겹치는 path가 있을 경우 앞에 렌더된 path(z-order 낮은 것)를 선택할지 뒤를 선택할지? → SVG 소스 순서상 마지막(위) path 우선.
3. **배경 path 처리**: `#FEFEFE`(흰색에 가까운) fill path는 색칠 대상에서 제외할지? → 확인 후 결정.
