## 1. DrawingElement 모델 추상화

- [x] 1.1 `DrawingElement` 추상 클래스 생성 (`lib/shared/models/drawing_element.dart`) — `type`, `toJson()`, `fromJson()` 팩토리 포함
- [x] 1.2 기존 `Stroke`가 `DrawingElement`를 구현하도록 수정 — `type: "stroke"` 추가, 기존 직렬화 유지
- [x] 1.3 `DrawingData.strokes`를 `List<DrawingElement>`로 교체 — 필드명 `elements`로 변경, JSON 키도 동일하게
- [x] 1.4 `DrawingElement.fromJson` 팩토리에서 `type` 필드 분기 구현 — `type` 없는 구 데이터는 `Stroke`로 폴백
- [x] 1.5 `DrawingTool` 열거형에 `rainbowBrush`, `sparkleBrush` 추가

## 2. RainbowStroke 구현

- [x] 2.1 `RainbowStroke` 클래스 생성 (`lib/shared/models/rainbow_stroke.dart`) — `points: List<Offset>`, `colors: List<Color>`, `size: double`, `blurSigma: double`
- [x] 2.2 `RainbowStroke.toJson()` / `fromJson()` 구현 — `type: "rainbow_stroke"`, colors는 ARGB int 리스트로 저장
- [x] 2.3 무지개 붓 색상 계산 헬퍼 구현 — `hue = (elapsedMs / 10000) * 360`, HSL → Color 변환
- [x] 2.4 `RainbowStrokePainter` CustomPainter 구현 — 인접 포인트 간 `ui.Gradient.linear`로 색상 보간 세그먼트 렌더링
- [x] 2.5 `MaskFilter.blur` 소프트 브러시 적용 — `blurSigma` 기본값 `size * 0.3`

## 3. SparkleElement 구현

- [x] 3.1 `SparkleShape` 열거형 생성 — `star`, `heart`, `circle`
- [x] 3.2 `SparkleObject` 데이터 클래스 생성 — `position`, `shape`, `color`, `finalSize`, `rotation`
- [x] 3.3 `SparkleElement` 클래스 생성 (`lib/shared/models/sparkle_element.dart`) — `palette: List<Color>`, `objects: List<SparkleObject>`
- [x] 3.4 `SparkleElement.toJson()` / `fromJson()` 구현 — `type: "sparkle"`
- [x] 3.5 개발용 파티클 도형 렌더러 구현 (`lib/shared/widgets/sparkle_shape_painter.dart`) — star/heart/circle을 Canvas API로 직접 드로잉
- [x] 3.6 `SparkleObjectWidget` 구현 — `AnimationController`로 크기 0 → `finalSize` 애니메이션 (300ms, elastic out), 완료 후 정적 렌더링
- [x] 3.7 `SparkleElementPainter` CustomPainter 구현 — 애니메이션 완료된 오브젝트들을 정적으로 렌더링

## 4. 랜덤 팔레트 생성

- [x] 4.1 팔레트 생성 유틸리티 구현 — 3~5개 색상을 HSL 색상환에서 고르게 분산하여 랜덤 선택
- [x] 4.2 꽃씨 붓 도구 선택 시 팔레트 초기화 로직 연동 — Provider 또는 상태에서 관리

## 5. 드로잉 Provider 및 입력 처리

- [x] 5.1 `FreeDrawingProvider` 에 무지개 붓 획 추가 로직 구현 — 포인트 추가 시 현재 시각 기반 색상 계산 후 `RainbowStroke` 업데이트
- [x] 5.2 `FreeDrawingProvider` 에 꽃씨 붓 오브젝트 생성 로직 구현 — 20px 거리 threshold마다 `SparkleObject` 생성, 팔레트에서 랜덤 색상 선택, 랜덤 도형/회전 적용
- [x] 5.3 `FreeDrawingProvider` 의 실행 취소 로직이 `DrawingElement` 타입에 관계없이 동작하도록 확인

## 6. 도구 선택 UI 업데이트

- [x] 6.1 `tool_selector.dart`에 무지개 붓 버튼 추가 — 아이콘 및 라벨
- [x] 6.2 `tool_selector.dart`에 꽃씨 붓 버튼 추가 — 아이콘 및 라벨

## 7. 캔버스 렌더링 통합

- [x] 7.1 `FreeDrawingPainter` (또는 메인 캔버스 CustomPainter)가 `DrawingElement` 타입별로 적절한 Painter를 호출하도록 수정
- [x] 7.2 꽃씨 붓 애니메이션 중인 오브젝트를 위젯 레이어에서 오버레이로 렌더링하는 구조 구현

## 8. 검증

- [x] 8.1 무지개 붓으로 그린 획이 저장/불러오기 후 동일하게 렌더링되는지 확인
- [x] 8.2 꽃씨 붓 파티클이 저장/불러오기 후 위치·색상·크기 그대로 복원되는지 확인
- [x] 8.3 구 데이터(`type` 필드 없음) 불러오기 시 크래시 없이 동작하는지 확인
- [x] 8.4 두 도구의 실행 취소가 올바르게 동작하는지 확인
