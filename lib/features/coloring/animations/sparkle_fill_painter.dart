import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_shape_painter.dart';
import 'fill_animation_painter.dart';

class SparkleFillPainter extends FillAnimationPainter {
  final List<_Particle> _particles;

  SparkleFillPainter._(this._particles);

  factory SparkleFillPainter.generate(Rect bounds, Color fillColor) {
    final rng = math.Random();
    final count = 60 + rng.nextInt(40); // 60~100개
    final particles = List.generate(count, (i) {
      final shape = SparkleShape.values[rng.nextInt(SparkleShape.values.length)];
      final size = 8.0 + rng.nextDouble() * 14.0; // 8~22px
      final lightColor = _lighten(fillColor, 0.3 + rng.nextDouble() * 0.3);
      return _Particle(
        position: Offset(
          bounds.left + rng.nextDouble() * bounds.width,
          bounds.top + rng.nextDouble() * bounds.height,
        ),
        shape: shape,
        color: lightColor,
        finalSize: size,
        rotation: rng.nextDouble() * math.pi * 2,
        delay: rng.nextDouble() * 0.15, // 0~150ms 딜레이
      );
    });
    return SparkleFillPainter._(particles);
  }

  @override
  Duration get duration => const Duration(milliseconds: 900);

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

    // 1. 파티클 그리기 (t < 0.9)
    if (t < 0.9) {
      for (final p in _particles) {
        final localT = ((t - p.delay) / 0.22).clamp(0.0, 1.0);
        if (localT <= 0) continue;
        final flicker = (math.sin(t * 18 + p.delay * 30) * 0.35 + 0.65)
            .clamp(0.0, 1.0);
        final scale = _elasticOut(localT);
        final obj = SparkleObject(
          position: p.position,
          shape: p.shape,
          color: p.color.withValues(alpha: localT * flicker),
          finalSize: p.finalSize,
          rotation: p.rotation,
        );
        drawSparkleObject(canvas, obj, scale: scale);
      }
    }

    // 2. Solid fill fade-in (t > 0.67)
    if (t > 0.67) {
      final fillT = ((t - 0.67) / 0.33).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = fillColor.withValues(alpha: fillT)
        ..style = PaintingStyle.fill;
      canvas.drawPath(targetPath, paint);
    }

    canvas.restore();
  }

  static double _elasticOut(double t) {
    if (t == 0 || t == 1) return t;
    return math.pow(2, -10 * t) *
            math.sin((t - 0.075) * (2 * math.pi) / 0.3) +
        1;
  }

  static Color _lighten(Color color, double amount) {
    return Color.fromARGB(
      255,
      (color.r * 255 + (255 - color.r * 255) * amount).round().clamp(0, 255),
      (color.g * 255 + (255 - color.g * 255) * amount).round().clamp(0, 255),
      (color.b * 255 + (255 - color.b * 255) * amount).round().clamp(0, 255),
    );
  }
}

class _Particle {
  final Offset position;
  final SparkleShape shape;
  final Color color;
  final double finalSize;
  final double rotation;
  final double delay;

  const _Particle({
    required this.position,
    required this.shape,
    required this.color,
    required this.finalSize,
    required this.rotation,
    required this.delay,
  });
}
