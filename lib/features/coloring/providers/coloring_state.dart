import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';

class ColoringState {
  final List<ColoringPath> parsedPaths;

  /// index → 실제 채워진 색상 (사용자가 선택한 색)
  final Map<int, Color> filledPaths;

  final bool isAnimating;
  final bool isCompleted;

  /// 현재 사용자가 선택한 팔레트 색상
  final Color? selectedColor;

  const ColoringState({
    required this.parsedPaths,
    required this.filledPaths,
    required this.isAnimating,
    required this.isCompleted,
    this.selectedColor,
  });

  factory ColoringState.initial() => const ColoringState(
        parsedPaths: [],
        filledPaths: {},
        isAnimating: false,
        isCompleted: false,
      );

  List<ColoringPath> get interactivePaths =>
      parsedPaths.where((p) => p.isInteractive).toList();

  /// SVG의 interactive path에서 추출한 중복 없는 색상 목록 (팔레트용).
  List<Color> get paletteColors {
    final seen = <Color>{};
    return interactivePaths
        .map((p) => p.fillColor)
        .where(seen.add)
        .toList();
  }

  ColoringState copyWith({
    List<ColoringPath>? parsedPaths,
    Map<int, Color>? filledPaths,
    bool? isAnimating,
    bool? isCompleted,
    Color? selectedColor,
  }) {
    return ColoringState(
      parsedPaths: parsedPaths ?? this.parsedPaths,
      filledPaths: filledPaths ?? this.filledPaths,
      isAnimating: isAnimating ?? this.isAnimating,
      isCompleted: isCompleted ?? this.isCompleted,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }
}
