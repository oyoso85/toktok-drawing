## Why

현재 앱은 기능은 구현되어 있지만 유아 대상 앱으로서 시각적 쾌감이 부족하다. 도구 선택바·색상 팔레트·버튼 등 UI 크롬 전반이 단조로운 회색/흰색 배경으로 이루어져 있고, 터치에 대한 시각적 피드백(애니메이션, 이팩트)이 없어 목업 수준으로 느껴진다.

## What Changes

- **ToolSelector**: 각 도구에 고유 컬러 부여, 선택 시 glow 효과 + scale bounce 애니메이션
- **BrushSizeSelector**: 검정 점 → 컬러 점, 선택 시 bounce
- **ColorPalette**: 색상 선택 시 scale 팝 + border pulse 애니메이션
- **DrawingToolbar**: 흰 배경 → 파스텔 그라디언트 배경
- **ModeSelectionScreen**: 모드 카드 컬러 강화, 탭 bounce + 진입 애니메이션
- **공통 bounce 유틸**: 재사용 가능한 AnimatedPressable 위젯 도입

## Capabilities

### New Capabilities
- `ui-chrome-visual`: 유아 친화적 UI 크롬 — 도구별 컬러, 그라디언트 배경, bounce/glow/pulse 인터랙션 애니메이션 시스템

### Modified Capabilities
(없음)

## Impact

- `lib/shared/widgets/tool_selector.dart`
- `lib/shared/widgets/brush_size_selector.dart`
- `lib/shared/widgets/color_palette.dart`
- `lib/shared/widgets/drawing_toolbar.dart`
- `lib/features/mode_selection/mode_selection_screen.dart`
- `lib/core/constants/app_colors.dart` (도구 컬러 팔레트 추가)
- 신규: `lib/shared/widgets/animated_pressable.dart`
- 신규: `lib/core/constants/tool_colors.dart`
