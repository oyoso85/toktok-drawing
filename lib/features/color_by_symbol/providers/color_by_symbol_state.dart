import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';

class ColorBySymbolState {
  /// regionIndex → 채워진 색상
  final Map<int, Color> filledRegions;

  /// 현재 선택된 색상
  final Color selectedColor;

  /// 전체 영역 수 (완료 판정에 사용)
  final int totalRegions;

  const ColorBySymbolState({
    required this.filledRegions,
    required this.selectedColor,
    required this.totalRegions,
  });

  factory ColorBySymbolState.initial() => ColorBySymbolState(
        filledRegions: const {},
        selectedColor: AppColors.palette.first,
        totalRegions: 0,
      );

  bool get isComplete =>
      totalRegions > 0 && filledRegions.length >= totalRegions;

  ColorBySymbolState copyWith({
    Map<int, Color>? filledRegions,
    Color? selectedColor,
    int? totalRegions,
  }) {
    return ColorBySymbolState(
      filledRegions: filledRegions ?? this.filledRegions,
      selectedColor: selectedColor ?? this.selectedColor,
      totalRegions: totalRegions ?? this.totalRegions,
    );
  }
}
