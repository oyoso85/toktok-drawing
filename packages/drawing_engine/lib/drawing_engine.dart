/// drawing_engine
///
/// 캔버스, 브러시, 채우기 알고리즘, 색상 팔레트, undo/redo 엔진.
/// 모든 그림 앱의 핵심 패키지. 다른 패키지들이 이 패키지에 의존함.
///
/// TODO: 아래 파일들을 toktok-drawing에서 이 패키지로 이동:
///   - shared/models/drawing_element.dart  → lib/models/drawing_element.dart
///   - shared/models/drawing_tool.dart     → lib/models/drawing_tool.dart
///   - shared/models/drawing_mode.dart     → lib/models/drawing_mode.dart
///   - shared/models/stroke.dart           → lib/models/stroke.dart
///   - shared/models/rainbow_stroke.dart   → lib/models/rainbow_stroke.dart
///   - shared/models/sparkle_element.dart  → lib/models/sparkle_element.dart
///   - shared/painters/stroke_painter_mixin.dart → lib/painters/stroke_painter_mixin.dart
///   - core/constants/app_colors.dart      → lib/constants/app_colors.dart
///   - core/constants/tool_colors.dart     → lib/constants/tool_colors.dart
///   - core/utils/palette_utils.dart       → lib/utils/palette_utils.dart
///   - core/theme/app_theme.dart           → lib/theme/app_theme.dart
library drawing_engine;
