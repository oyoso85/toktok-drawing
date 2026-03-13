## Context

Flutter web 기반 유아 드로잉 앱. 기능 구현은 완료되었으나 UI 크롬(도구바, 팔레트, 버튼)이 기본 Material 스타일 그대로여서 유아 대상으로 시각적 쾌감이 부족하다.

현재 상태:
- `ToolSelector`: 회색 박스 + Material 아이콘, 선택 시 파랑/보라 배경 변화만
- `ColorPalette`: 선택 시 파란 테두리 + 그림자만
- `BrushSizeSelector`: 흰 배경에 검정 점
- `DrawingToolbar`: 흰 배경 `Colors.white`
- `ModeSelectionScreen`: 연한 파스텔 카드, 탭 피드백 없음
- 공통 bounce 애니메이션 없음

## Goals / Non-Goals

**Goals:**
- 모든 대화형 요소에 bounce/scale 터치 피드백 추가
- 도구별 고유 컬러로 ToolSelector를 시각적으로 풍성하게
- ColorPalette 선택 시 scale pop + 색상 glow
- DrawingToolbar 배경을 파스텔 그라디언트로
- ModeSelectionScreen 카드 컬러 강화 + 진입 페이드인

**Non-Goals:**
- 사운드 효과
- 그리기 중 파티클 꼬리 효과 (경로 3)
- 색칠 채우기 애니메이션 (별도 작업)

## Decisions

### 1. AnimatedPressable — 공통 bounce 위젯

**결정**: `lib/shared/widgets/animated_pressable.dart` 신규 생성, `GestureDetector` + `AnimationController`로 scale bounce 구현.

```
탭 다운 → scale 0.85  (80ms, Curves.easeIn)
탭 업   → scale 1.1   (100ms, Curves.elasticOut)
완료    → scale 1.0   (80ms, Curves.easeOut)
```

**대안**: Flutter의 `InkWell` ripple → 유아에게 ripple은 너무 성인 Material 느낌, 통통 튀기가 더 직관적.

### 2. 도구별 컬러 — ToolColors 상수

**결정**: `lib/core/constants/tool_colors.dart` 신규 생성.

| 도구      | 배경(미선택) | 배경(선택) | 아이콘 |
|----------|------------|---------|------|
| pen      | #E3F2FD    | #4FC3F7 | white |
| brush    | #E8F5E9    | #81C784 | white |
| pencil   | #FFF3E0    | #FFB74D | white |
| eraser   | #F3E5F5    | #CE93D8 | white |
| rainbow  | shimmer gradient | rainbow gradient | white |
| sparkle  | #FCE4EC    | #F48FB1 | white |

선택된 도구: 배경 채움 + `boxShadow` glow (해당 색 0.6 alpha, blurRadius 8).

### 3. ToolSelector 아이콘 교체

**결정**: 기존 Material 아이콘 유지하되 크기를 24→28 확대, 텍스트 레이블 fontSize 9→10, 컨테이너 48×52→52×58.

**대안**: 커스텀 이미지 아이콘 → 에셋 관리 부담, 추후 별도 작업.

### 4. ColorPalette 선택 애니메이션

**결정**: 선택된 색상 원을 `AnimatedContainer`로 42×42 → 50×50 scale, border를 흰색+3px로 변경, 해당 색상 glow 유지.

`AnimatedContainer` duration: 200ms, curve: Curves.elasticOut.

### 5. DrawingToolbar 그라디언트

**결정**: `LinearGradient` — `Color(0xFFFFF9F0)` → `Color(0xFFF0F9FF)` (크림→스카이, 매우 연하게).
테두리 상단에 1px 컬러풀 rainbow 선 추가 (6색 gradient).

### 6. ModeSelectionScreen 강화

**결정**: 모드 카드 배경색 강화 (채도 높임), 카드 진입 시 `FadeTransition` + `SlideTransition` (아래→위 20px, 100ms stagger).

## Risks / Trade-offs

- [AnimationController 메모리] ToolSelector에서 6개 도구 각각 AnimatedPressable 사용 → 최대 6개 controller. `StatefulWidget` + `dispose()` 철저히.
  → AnimatedPressable 내부에서 단일 controller 관리, `SingleTickerProviderStateMixin`.

- [flutter web 퍼포먼스] 여러 애니메이션 동시 실행 시 web renderer 부하.
  → 애니메이션 duration을 200ms 이내로 짧게 유지. `RepaintBoundary` 활용.

- [static const 재컴파일] ToolColors, AppColors 상수 변경 시 반드시 서버 재시작 + Ctrl+Shift+R.
