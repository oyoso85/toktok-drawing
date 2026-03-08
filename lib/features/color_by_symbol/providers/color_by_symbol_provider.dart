import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/features/color_by_symbol/models/coloring_template.dart';
import 'color_by_symbol_state.dart';

/// 7.9 숫자/ABC 색칠 모드 Riverpod Provider
class ColorBySymbolNotifier extends Notifier<ColorBySymbolState> {
  @override
  ColorBySymbolState build() => ColorBySymbolState.initial();

  /// 새 템플릿 선택 시 상태 초기화
  void initForTemplate(ColoringTemplate template) {
    state = state.copyWith(
      filledRegions: {},
      totalRegions: template.regions.length,
    );
  }

  /// 7.6 영역 탭 → 현재 선택 색상으로 채우기
  void fillRegion(int regionIndex) {
    state = state.copyWith(
      filledRegions: {...state.filledRegions, regionIndex: state.selectedColor},
    );
  }

  /// 색상 변경
  void changeColor(Color color) => state = state.copyWith(selectedColor: color);

  /// 7.8 초기화: 모든 색칠 제거
  void reset() => state = state.copyWith(filledRegions: {});
}

final colorBySymbolProvider =
    NotifierProvider<ColorBySymbolNotifier, ColorBySymbolState>(
  ColorBySymbolNotifier.new,
);
