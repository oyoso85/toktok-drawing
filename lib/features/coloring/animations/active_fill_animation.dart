import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'fill_animation_painter.dart';

/// 현재 진행 중인 채우기 애니메이션 하나의 스냅샷 (렌더용).
class ActiveFillAnimation {
  final FillAnimationPainter painter;
  final ui.Path targetPath;
  final Color fillColor;
  final Offset tapOffset;
  final double t;

  const ActiveFillAnimation({
    required this.painter,
    required this.targetPath,
    required this.fillColor,
    required this.tapOffset,
    required this.t,
  });
}
