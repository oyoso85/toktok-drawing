## 1. 공통 인프라

- [x] 1.1 `lib/core/constants/tool_colors.dart` 생성 — 각 DrawingTool의 고유 컬러(미선택/선택/glow) 상수 정의
- [x] 1.2 `lib/shared/widgets/animated_pressable.dart` 생성 — GestureDetector + AnimationController 기반 scale bounce 위젯 구현 (탭다운 0.85 → 탭업 1.1 → 1.0)

## 2. ToolSelector 리디자인

- [x] 2.1 `tool_selector.dart` — ToolColors 적용, 미선택 시 고유 컬러 연한 배경 / 선택 시 풀 채도 + glow boxShadow
- [x] 2.2 `tool_selector.dart` — 아이콘 색상: 미선택 회색 → 고유 컬러, 선택 흰색
- [x] 2.3 `tool_selector.dart` — 컨테이너 크기 48×52 → 52×58, 아이콘 20→24, 레이블 9→11
- [x] 2.4 `tool_selector.dart` — GestureDetector → AnimatedPressable로 교체

## 3. ColorPalette 선택 애니메이션

- [x] 3.1 `color_palette.dart` — AnimatedContainer로 선택 원 42px → 50px scale pop (200ms, Curves.elasticOut)
- [x] 3.2 `color_palette.dart` — 선택 시 테두리 색상 파란색 → 흰색 3px로 변경

## 4. BrushSizeSelector 리디자인

- [x] 4.1 `brush_size_selector.dart` — 점 색상을 검정 → 크기별 그라디언트 컬러 (작→큰: 파랑→주황→핑크→보라)
- [x] 4.2 `brush_size_selector.dart` — 선택된 점 배경을 흰색 원으로 강조, AnimatedPressable 적용

## 5. DrawingToolbar 배경 개선

- [x] 5.1 `drawing_toolbar.dart` — 배경 `Colors.white` → 크림-스카이 LinearGradient
- [x] 5.2 `drawing_toolbar.dart` — 상단에 1px 높이 6색 rainbow gradient 구분선 추가

## 6. ModeSelectionScreen 강화

- [x] 6.1 `mode_selection_screen.dart` — 모드 카드 배경색 채도 강화 (자유: 주황, 선따라: 초록, 색칠: 파랑, 대칭: 보라)
- [x] 6.2 `mode_selection_screen.dart` — 화면 진입 시 카드 FadeIn + SlideTransition (아래→위 20px, 100ms stagger)
- [x] 6.3 `mode_card.dart` (또는 ModeSelectionScreen 내) — 카드 탭을 AnimatedPressable로 감싸기
- [x] 6.4 `mode_selection_screen.dart` — 배경 장식 원의 alpha 0.05~0.10 → 0.15~0.25로 높여 가시성 개선

## 7. 검증

- [x] 7.1 flutter web 서버 재시작 후 localhost:8080 에서 도구 선택 bounce 확인
- [x] 7.2 색상 팔레트 선택 scale pop 확인
- [x] 7.3 ModeSelection 진입 애니메이션 확인
- [x] 7.4 모바일 뷰(375px)에서 레이아웃 깨짐 없는지 확인
