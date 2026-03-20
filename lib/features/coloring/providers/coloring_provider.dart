import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/features/coloring/models/svg_coloring_parser.dart';
import 'coloring_state.dart';

class ColoringNotifier extends Notifier<ColoringState> {
  @override
  ColoringState build() => ColoringState.initial();

  /// SVG 파일을 로드하고 파싱하여 상태 초기화.
  /// 파싱 완료 후 팔레트 첫 번째 색상을 자동 선택.
  Future<void> initPaths(String svgAssetPath) async {
    final svgString = await rootBundle.loadString(svgAssetPath);
    final paths = SvgColoringParser.parse(svgString);
    final viewBox = SvgColoringParser.parseViewBox(svgString);

    final firstColor = paths
        .where((p) => p.isInteractive)
        .map((p) => p.fillColor)
        .toSet()
        .firstOrNull;

    state = state.copyWith(
      parsedPaths: paths,
      filledPaths: {},
      isCompleted: false,
      selectedColor: firstColor,
      svgViewBox: viewBox,
    );
  }

  /// 특정 path를 채워진 상태로 전환하고 완성 여부를 체크.
  void fillPath(int index, Color color) {
    final updated = {...state.filledPaths, index: color};
    final isCompleted =
        state.interactivePaths.every((p) => updated.containsKey(p.index));

    state = state.copyWith(
      filledPaths: updated,
      isCompleted: isCompleted,
    );
  }

  /// 아직 채워지지 않은 모든 interactive path를 원본 색상으로 채움 (자동 완성).
  void fillAllRemaining() {
    final updated = Map<int, Color>.from(state.filledPaths);
    for (final p in state.interactivePaths) {
      updated.putIfAbsent(p.index, () => p.fillColor);
    }
    state = state.copyWith(
      filledPaths: updated,
      isCompleted: true,
    );
  }

  void selectColor(Color color) {
    state = state.copyWith(selectedColor: color);
  }

  void resetCompletion() {
    state = state.copyWith(isCompleted: false);
  }
}

final coloringProvider =
    NotifierProvider<ColoringNotifier, ColoringState>(ColoringNotifier.new);
