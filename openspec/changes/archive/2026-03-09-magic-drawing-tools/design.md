## Context

현재 `DrawingData`는 `List<Stroke>`를 가지고, 각 `Stroke`는 포인트 목록 + 단일 색상 + 굵기 + 도구 타입으로 구성된다. 무지개 붓(포인트별 색상)과 꽃씨 붓(오브젝트 집합)은 이 구조에 맞지 않는다. 도구를 추가할수록 "선 하나"로는 표현이 불가능한 요소가 늘어날 것이므로 캔버스 요소 타입 시스템을 먼저 추상화한다.

## Goals / Non-Goals

**Goals:**
- `DrawingElement` 추상 타입으로 캔버스 요소 통합 — 미래 도구 추가를 위한 확장점
- 무지개 붓 (`RainbowStroke`): 포인트별 색상 저장, 소프트 브러시 렌더링
- 꽃씨 붓 (`SparkleElement`): 피어나는 파티클 오브젝트, 랜덤 팔레트, 영구 잔류
- 저장/불러오기 일관성: JSON 타입 디스크리미네이터로 역직렬화

**Non-Goals:**
- 기존 Stroke, 펜/붓/색연필 동작 변경
- 실시간 멀티플레이어 동기화
- SVG 오브젝트 에셋 (개발용 기본 도형만)
- 기존 저장 데이터 마이그레이션 (프로토타입 — 기존 파일 무효화 허용)

## Decisions

### 1. DrawingElement 추상 클래스

```
abstract class DrawingElement {
  String get type;           // JSON 타입 디스크리미네이터
  Map<String, dynamic> toJson();
  static DrawingElement fromJson(Map<String, dynamic> json)
    → type 필드로 Stroke / RainbowStroke / SparkleElement 분기
}
```

기존 `Stroke`는 `DrawingElement`를 구현하도록 변경. `DrawingData.strokes`는 `List<DrawingElement>`로 교체.

**대안 고려:** sealed class (Dart 3) → 패턴 매칭 가능하나 현재 코드베이스 패턴과 거리가 있어 단순 추상 클래스 채택.

---

### 2. 무지개 붓 — RainbowStroke

**색상 저장 방식:** 포인트별 Color 저장 (시각 저장 대신)

```
class RainbowStroke extends DrawingElement {
  List<Offset> points;
  List<Color> colors;   // points와 1:1 대응
  double size;
  double blurSigma;     // 소프트 브러시 흐림 강도 (기본값 TBD)
}
```

색상 계산: 손가락이 이동하는 동안 경과 시간을 `hue = (elapsedMs / 10000) * 360`로 HSL 변환. 렌더링 시 인접 포인트 간 세그먼트마다 시작/끝 색상을 `ui.Gradient.linear`로 보간.

소프트 브러시: `Paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)`. `blurSigma`는 `size`에 비례한 기본값으로 시작, 나중에 조정.

**대안 고려:** 시각(timestamp) 저장 → 불러올 때 색상이 달라짐. 포인트별 색상 저장 채택.

---

### 3. 꽃씨 붓 — SparkleElement

```
class SparkleObject {
  Offset position;
  SparkleShape shape;   // star, heart, circle (SVG 교체 예정)
  Color color;
  double finalSize;
  double rotation;
}

class SparkleElement extends DrawingElement {
  List<Color> palette;        // 입장 시 결정된 랜덤 팔레트 (3~5색)
  List<SparkleObject> objects;
}
```

**파티클 생성 간격:** 포인트 이동 거리가 일정 threshold(예: 20px) 이상일 때마다 오브젝트 추가. 너무 촘촘하지 않게.

**애니메이션 분리 원칙:** `SparkleObject` 자체는 최종 상태(finalSize)만 저장. 피어나는 애니메이션(0 → finalSize, ~300ms)은 위젯 레이어 `AnimationController`로 처리. 애니메이션 완료 후 CustomPainter에서 정적 렌더링.

**대안 고려:** Stroke에 파티클 정보를 함께 저장 → 타입 혼재, 나중에 SVG 교체 어려움. DrawingElement 분리 채택.

---

### 4. JSON 직렬화 — 타입 디스크리미네이터

```json
{ "type": "stroke",         ...Stroke 필드... }
{ "type": "rainbow_stroke", "points": [...], "colors": [...], "size": 10, "blurSigma": 3.0 }
{ "type": "sparkle",        "palette": [...], "objects": [...] }
```

`DrawingElement.fromJson`에서 `type` 필드로 분기. 구 데이터(`type` 필드 없음) → `stroke`로 처리.

---

### 5. DrawingTool 열거형 확장

```dart
enum DrawingTool { pen, brush, pencil, eraser, rainbowBrush, sparkleBrush }
```

도구 선택 UI(`tool_selector.dart`)에 두 항목 추가. 기존 도구는 변경 없음.

## Risks / Trade-offs

- **기존 저장 데이터 비호환** → 프로토타입이므로 허용. 구 데이터 로드 시 `type` 없으면 Stroke로 처리하는 폴백으로 크래시 방지.
- **소프트 브러시 성능** → `MaskFilter.blur`는 GPU에서 처리되나 포인트가 많아지면 부하. 포인트 decimation(거리 threshold)으로 완화.
- **꽃씨 붓 AnimationController 관리** → 여러 오브젝트가 동시에 애니메이션할 때 컨트롤러 누적. 애니메이션 완료 즉시 dispose 처리 필요.
- **blurSigma 튜닝 미정** → 기본값으로 시작하고 사용자 피드백 후 조정. 추후 별도 슬라이더 UI 가능.

## Open Questions

- 꽃씨 붓 파티클 생성 간격 threshold: 20px가 적당한가? 직접 테스트 후 확정.
- 소프트 브러시 `blurSigma` 기본값: `size * 0.3` 정도로 시작.
- 꽃씨 붓 오브젝트 최대 개수 제한 필요 여부 (메모리/성능).
