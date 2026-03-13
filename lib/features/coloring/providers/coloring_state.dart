import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';

class ColoringState {
  final List<ColoringPath> parsedPaths;
  final Set<int> filledPaths;
  final bool isAnimating;
  final bool isCompleted;

  const ColoringState({
    required this.parsedPaths,
    required this.filledPaths,
    required this.isAnimating,
    required this.isCompleted,
  });

  factory ColoringState.initial() => const ColoringState(
        parsedPaths: [],
        filledPaths: {},
        isAnimating: false,
        isCompleted: false,
      );

  List<ColoringPath> get interactivePaths =>
      parsedPaths.where((p) => p.isInteractive).toList();

  ColoringState copyWith({
    List<ColoringPath>? parsedPaths,
    Set<int>? filledPaths,
    bool? isAnimating,
    bool? isCompleted,
  }) {
    return ColoringState(
      parsedPaths: parsedPaths ?? this.parsedPaths,
      filledPaths: filledPaths ?? this.filledPaths,
      isAnimating: isAnimating ?? this.isAnimating,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
