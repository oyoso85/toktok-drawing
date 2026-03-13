import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'fill_animation_painter.dart';

class PaintFloodFillPainter extends FillAnimationPainter {
  const PaintFloodFillPainter();

  @override
  Duration get duration => const Duration(milliseconds: 700);

  @override
  void paint(
    Canvas canvas,
    Size size,
    ui.Path targetPath,
    Color fillColor,
    double t,
    Offset tapOffset,
  ) {
    canvas.save();
    canvas.clipPath(targetPath);

    final bounds = targetPath.getBounds();
    final diagonal = math.sqrt(
      bounds.width * bounds.width + bounds.height * bounds.height,
    );

    // ease-out 확장 (빠르게 퍼지다 가장자리에서 감속)
    final eased = 1 - math.pow(1 - t, 2.5);
    final radius = diagonal * eased;

    final opacity = (0.85 + 0.15 * t).clamp(0.0, 1.0);

    // 가장자리 블러로 물감 번짐 느낌
    final paint = Paint()
      ..color = fillColor.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(tapOffset, radius, paint);

    // 블러 없는 solid 레이어를 약간 작게 겹쳐 중심부를 선명하게
    if (radius > 10) {
      final solidPaint = Paint()
        ..color = fillColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tapOffset, radius * 0.85, solidPaint);
    }

    canvas.restore();
  }
}
