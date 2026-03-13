import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'fill_animation_painter.dart';

class PencilFillPainter extends FillAnimationPainter {
  final List<_Stroke> _strokes;
  final ui.FragmentProgram? pencilProgram;

  PencilFillPainter._(this._strokes, this.pencilProgram);

  factory PencilFillPainter.generate(
      Rect bounds, Color fillColor, ui.FragmentProgram? pencilProgram) {
    final rng = math.Random();
    // 선분 총 개수: 밀도를 면적에 비례
    final area = bounds.width * bounds.height;
    final count = (area / 80).clamp(60, 400).toInt();

    // 주 방향: 약간 기울어진 사선 (±30°) + 소수의 크로스 해치
    const baseAngle = math.pi / 5; // 36°

    final strokes = List.generate(count, (i) {
      final ratio = i / count; // 이 선분이 등장하는 시간 비율
      final isCross = rng.nextDouble() < 0.25; // 25%는 다른 방향
      final angle = isCross
          ? baseAngle + math.pi / 2 + (rng.nextDouble() - 0.5) * 0.4
          : baseAngle + (rng.nextDouble() - 0.5) * 0.5;

      final length = 18.0 + rng.nextDouble() * 40.0;
      final cx = bounds.left + rng.nextDouble() * bounds.width;
      final cy = bounds.top + rng.nextDouble() * bounds.height;

      return _Stroke(
        start: Offset(
          cx - math.cos(angle) * length / 2,
          cy - math.sin(angle) * length / 2,
        ),
        end: Offset(
          cx + math.cos(angle) * length / 2,
          cy + math.sin(angle) * length / 2,
        ),
        width: 1.2 + rng.nextDouble() * 1.6,
        opacity: 0.55 + rng.nextDouble() * 0.35,
        timeRatio: ratio,
      );
    });
    return PencilFillPainter._(strokes, pencilProgram);
  }

  @override
  Duration get duration => const Duration(milliseconds: 1000);

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

    // 1. 선분 누적 (t < 0.8)
    final strokePhase = (t / 0.8).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = fillColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final s in _strokes) {
      if (s.timeRatio > strokePhase) break;
      paint.strokeWidth = s.width;
      paint.color = fillColor.withValues(alpha: s.opacity);
      canvas.drawLine(s.start, s.end, paint);
    }

    // 2. Solid fill fade-in 마무리 (t > 0.75)
    if (t > 0.75) {
      final fillT = ((t - 0.75) / 0.25).clamp(0.0, 1.0);
      final solidPaint = Paint()
        ..color = fillColor.withValues(alpha: fillT)
        ..style = PaintingStyle.fill;
      canvas.drawPath(targetPath, solidPaint);
    }

    canvas.restore();
  }
}

class _Stroke {
  final Offset start;
  final Offset end;
  final double width;
  final double opacity;
  final double timeRatio; // 0.0~1.0: 이 선이 등장하는 strokePhase 시점

  const _Stroke({
    required this.start,
    required this.end,
    required this.width,
    required this.opacity,
    required this.timeRatio,
  });
}
