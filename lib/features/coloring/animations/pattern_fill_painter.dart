import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_shape_painter.dart';
import 'fill_animation_painter.dart';

class PatternFillPainter extends FillAnimationPainter {
  final List<_Cell> _cells;

  PatternFillPainter._(this._cells);

  factory PatternFillPainter.generate(
      Rect bounds, Color fillColor, Offset tapOffset) {
    final rng = math.Random();
    const cellSize = 18.0;
    final cols = (bounds.width / cellSize).ceil();
    final rows = (bounds.height / cellSize).ceil();
    final maxDist = math.sqrt(
        math.pow(bounds.width, 2) + math.pow(bounds.height, 2));

    final cells = <_Cell>[];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = bounds.left + col * cellSize + cellSize / 2;
        final cy = bounds.top + row * cellSize + cellSize / 2;
        final dist = (Offset(cx, cy) - tapOffset).distance;
        final delay = (dist / maxDist) * 0.55; // 0~550ms ripple delay

        final shape =
            SparkleShape.values[rng.nextInt(SparkleShape.values.length)];
        final rotation = rng.nextDouble() * math.pi * 2;

        cells.add(_Cell(
          center: Offset(cx, cy),
          shape: shape,
          color: _varyColor(fillColor, rng),
          size: cellSize * 0.65,
          rotation: rotation,
          delay: delay,
        ));
      }
    }
    return PatternFillPainter._(cells);
  }

  @override
  Duration get duration => const Duration(milliseconds: 850);

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

    // 1. 셀 도형 등장 (t < 0.75)
    if (t < 0.82) {
      for (final cell in _cells) {
        final localT = ((t - cell.delay) / 0.18).clamp(0.0, 1.0);
        if (localT <= 0) continue;
        final scale = _elasticOut(localT);
        final obj = SparkleObject(
          position: cell.center,
          shape: cell.shape,
          color: cell.color.withValues(alpha: localT.clamp(0.0, 1.0)),
          finalSize: cell.size,
          rotation: cell.rotation,
        );
        drawSparkleObject(canvas, obj, scale: scale);
      }
    }

    // 2. Solid fill fade-in (t > 0.70)
    if (t > 0.70) {
      final fillT = ((t - 0.70) / 0.30).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = fillColor.withValues(alpha: fillT)
        ..style = PaintingStyle.fill;
      canvas.drawPath(targetPath, paint);
    }

    canvas.restore();
  }

  static double _elasticOut(double t) {
    if (t == 0 || t == 1) return t;
    return math.pow(2, -8 * t) *
            math.sin((t - 0.1) * (2 * math.pi) / 0.4) +
        1;
  }

  static Color _varyColor(Color base, math.Random rng) {
    final delta = rng.nextDouble() * 0.25;
    return Color.fromARGB(
      255,
      (base.r * 255 + (255 - base.r * 255) * delta).round().clamp(0, 255),
      (base.g * 255 + (255 - base.g * 255) * delta).round().clamp(0, 255),
      (base.b * 255 + (255 - base.b * 255) * delta).round().clamp(0, 255),
    );
  }
}

class _Cell {
  final Offset center;
  final SparkleShape shape;
  final Color color;
  final double size;
  final double rotation;
  final double delay;

  const _Cell({
    required this.center,
    required this.shape,
    required this.color,
    required this.size,
    required this.rotation,
    required this.delay,
  });
}
