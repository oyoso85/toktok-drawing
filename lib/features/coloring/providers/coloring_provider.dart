import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/features/coloring/models/svg_coloring_parser.dart';
import 'coloring_state.dart';

class ColoringNotifier extends Notifier<ColoringState> {
  @override
  ColoringState build() => ColoringState.initial();

  /// SVG 파일을 로드하고 파싱하여 상태 초기화.
  Future<void> initPaths() async {
    final svgString = await rootBundle.loadString(
      'assets/templates/coloring/character.svg',
    );
    final paths = SvgColoringParser.parse(svgString);
    state = state.copyWith(
      parsedPaths: paths,
      filledPaths: {},
      isCompleted: false,
    );
  }

  /// 특정 path를 채워진 상태로 전환하고 완성 여부를 체크.
  void fillPath(int index) {
    final updated = {...state.filledPaths, index};
    final interactive = state.interactivePaths;
    final isCompleted = interactive.every((p) => updated.contains(p.index));

    state = state.copyWith(
      filledPaths: updated,
      isCompleted: isCompleted,
    );
  }

  void setAnimating(bool value) {
    state = state.copyWith(isAnimating: value);
  }

  void resetCompletion() {
    state = state.copyWith(isCompleted: false);
  }
}

final coloringProvider =
    NotifierProvider<ColoringNotifier, ColoringState>(ColoringNotifier.new);
