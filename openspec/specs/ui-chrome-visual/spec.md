## ADDED Requirements

### Requirement: AnimatedPressable — 공통 bounce 터치 피드백
모든 대화형 버튼/카드는 `AnimatedPressable` 위젯을 통해 터치 시 scale bounce 피드백을 제공해야 한다.

- 탭 다운: scale 1.0 → 0.85 (80ms, Curves.easeIn)
- 탭 업: scale 0.85 → 1.1 (100ms, Curves.elasticOut) → 1.0 (80ms, Curves.easeOut)

#### Scenario: 버튼 탭 bounce
- **WHEN** 사용자가 대화형 버튼을 탭한다
- **THEN** 버튼이 눌리는 느낌의 scale 축소 후 통통 튀어오르는 애니메이션이 재생된다

#### Scenario: 빠른 연속 탭
- **WHEN** 사용자가 버튼을 연속으로 빠르게 탭한다
- **THEN** 각 탭마다 bounce가 재시작되며 시각적으로 응답한다

---

### Requirement: ToolSelector — 도구별 고유 컬러
각 도구 버튼은 도구의 특성을 나타내는 고유한 배경색을 가져야 한다.

- pen: 파랑 계열 (#4FC3F7)
- brush: 초록 계열 (#81C784)
- pencil: 주황 계열 (#FFB74D)
- eraser: 연보라 계열 (#CE93D8)
- rainbowBrush: rainbow shimmer 그라디언트
- sparkleBrush: 핫핑크 계열 (#F48FB1)

#### Scenario: 미선택 도구 표시
- **WHEN** 도구가 선택되지 않은 상태다
- **THEN** 해당 도구의 고유 컬러 연한 버전(alpha 0.25)이 배경에 표시된다

#### Scenario: 선택된 도구 표시
- **WHEN** 도구가 선택된다
- **THEN** 고유 컬러 배경이 풀 채도로 표시되고, 해당 색상의 glow(boxShadow)가 나타나며, 아이콘이 흰색으로 표시된다

#### Scenario: 도구 선택 시 bounce
- **WHEN** 사용자가 도구를 탭한다
- **THEN** AnimatedPressable bounce 피드백과 함께 선택 상태로 전환된다

---

### Requirement: ColorPalette — 선택 색상 scale pop
선택된 색상 원은 비선택 원보다 크게 표시되고 glow 효과를 가져야 한다.

#### Scenario: 색상 선택
- **WHEN** 사용자가 색상 원을 탭한다
- **THEN** 해당 원이 42px → 50px으로 확대되고, 해당 색상의 glow가 나타나며, 흰 테두리 3px가 표시된다

#### Scenario: 색상 전환 애니메이션
- **WHEN** 다른 색상을 선택한다
- **THEN** 이전 선택이 42px로, 새 선택이 50px으로 부드럽게 전환된다 (200ms, Curves.elasticOut)

---

### Requirement: DrawingToolbar — 파스텔 그라디언트 배경
툴바 배경은 단순 흰색 대신 부드러운 파스텔 그라디언트로 표시되어야 한다.

#### Scenario: 툴바 배경 렌더링
- **WHEN** DrawingToolbar가 화면에 표시된다
- **THEN** 크림(#FFF9F0) → 스카이(#F0F9FF) 수평 LinearGradient 배경이 렌더링된다

#### Scenario: 툴바 상단 컬러 구분선
- **WHEN** DrawingToolbar가 화면에 표시된다
- **THEN** 상단에 1px 높이의 6색 rainbow gradient 선이 표시된다

---

### Requirement: ModeSelectionScreen — 생동감 있는 카드
모드 선택 카드는 채도 높은 컬러와 진입 애니메이션을 가져야 한다.

#### Scenario: 화면 진입 애니메이션
- **WHEN** ModeSelectionScreen이 처음 표시된다
- **THEN** 각 카드가 아래에서 위로 20px 슬라이드 + FadeIn 되며, 카드 간 100ms stagger가 적용된다

#### Scenario: 카드 탭 피드백
- **WHEN** 사용자가 모드 카드를 탭한다
- **THEN** AnimatedPressable bounce 피드백 후 해당 화면으로 이동한다

#### Scenario: 카드 컬러
- **WHEN** 모드 카드가 표시된다
- **THEN** 기존 연한 파스텔보다 채도가 높은 배경색이 적용된다 (자유그리기: 주황, 선따라: 초록, 색칠: 파랑, 대칭: 보라 계열)
