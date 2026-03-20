import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';

class ColoringState {
  final List<ColoringPath> parsedPaths;

  /// index → 실제 채워진 색상 (사용자가 선택한 색)
  final Map<int, Color> filledPaths;

  final bool isCompleted;

  /// 현재 사용자가 선택한 팔레트 색상
  final Color? selectedColor;

  /// SVG viewBox 크기 (변환 행렬 계산에 사용)
  final Size svgViewBox;

  const ColoringState({
    required this.parsedPaths,
    required this.filledPaths,
    required this.isCompleted,
    this.selectedColor,
    this.svgViewBox = const Size(630, 648),
  });

  factory ColoringState.initial() => const ColoringState(
        parsedPaths: [],
        filledPaths: {},
        isCompleted: false,
      );

  List<ColoringPath> get interactivePaths =>
      parsedPaths.where((p) => p.isInteractive).toList();

  /// SVG의 interactive path에서 추출한 중복 없는 색상 목록 (팔레트용).
  /// 빨→주→노→초→파→남→보 무지개 순서 (HSV hue 기준 오름차순).
  List<Color> get paletteColors {
    final seen = <Color>{};
    final unique = interactivePaths
        .map((p) => p.fillColor)
        .where(seen.add)
        .toList();
    unique.sort((a, b) {
      final ha = HSVColor.fromColor(a).hue;
      final hb = HSVColor.fromColor(b).hue;
      return ha.compareTo(hb);
    });
    return unique;
  }

  ColoringState copyWith({
    List<ColoringPath>? parsedPaths,
    Map<int, Color>? filledPaths,
    bool? isCompleted,
    Color? selectedColor,
    Size? svgViewBox,
  }) {
    return ColoringState(
      parsedPaths: parsedPaths ?? this.parsedPaths,
      filledPaths: filledPaths ?? this.filledPaths,
      isCompleted: isCompleted ?? this.isCompleted,
      selectedColor: selectedColor ?? this.selectedColor,
      svgViewBox: svgViewBox ?? this.svgViewBox,
    );
  }
}
