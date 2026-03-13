import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'fill_animation_painter.dart';
import 'sparkle_fill_painter.dart';
import 'pattern_fill_painter.dart';
import 'paint_flood_fill_painter.dart';
import 'pencil_fill_painter.dart';

enum FillAnimationType { sparkle, pattern, paintFlood, pencil }

/// 4가지 채우기 효과 중 하나를 랜덤 선택하여 [FillAnimationPainter]를 생성.
class FillAnimationSelector {
  static final _rng = Random();

  static FillAnimationPainter select({
    required Rect bounds,
    required Color fillColor,
    required Offset tapOffset,
    ui.FragmentProgram? pencilProgram,
  }) {
    final type = FillAnimationType.values[_rng.nextInt(FillAnimationType.values.length)];
    return _create(type, bounds: bounds, fillColor: fillColor,
        tapOffset: tapOffset, pencilProgram: pencilProgram);
  }

  static FillAnimationPainter _create(
    FillAnimationType type, {
    required Rect bounds,
    required Color fillColor,
    required Offset tapOffset,
    ui.FragmentProgram? pencilProgram,
  }) {
    switch (type) {
      case FillAnimationType.sparkle:
        return SparkleFillPainter.generate(bounds, fillColor);
      case FillAnimationType.pattern:
        return PatternFillPainter.generate(bounds, fillColor, tapOffset);
      case FillAnimationType.paintFlood:
        return const PaintFloodFillPainter();
      case FillAnimationType.pencil:
        return PencilFillPainter.generate(bounds, fillColor, pencilProgram);
    }
  }
}
