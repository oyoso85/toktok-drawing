import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/rainbow_stroke.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_shape_painter.dart';

/// 공통 DrawingElement 렌더링 로직 mixin.
///
/// DrawingCanvas, TraceCanvas 등 모든 CustomPainter에서 사용.
/// 새 도구 옵션 추가 시 이 파일만 수정하면 모든 화면에 반영된다.
mixin StrokePainterMixin {
  /// 색연필 Fragment Shader 프로그램. null이면 그레인 파티클 fallback.
  ui.FragmentProgram? get pencilProgram;

  void drawElement(Canvas canvas, DrawingElement el) {
    if (el is Stroke) {
      drawStroke(canvas, el);
    } else if (el is RainbowStroke) {
      _drawRainbow(canvas, el);
    } else if (el is SparkleElement) {
      _drawSparkleElement(canvas, el);
    }
  }

  void drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    switch (stroke.tool) {
      case DrawingTool.pen:
        _drawPen(canvas, stroke);
      case DrawingTool.brush:
        _drawBrush(canvas, stroke);
      case DrawingTool.pencil:
        _drawPencil(canvas, stroke);
      case DrawingTool.eraser:
        _drawEraser(canvas, stroke);
      default:
        _drawPen(canvas, stroke);
    }
  }

  void _drawPen(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.size / 2, paint..style = PaintingStyle.fill);
      return;
    }
    canvas.drawPath(smoothPath(stroke.points), paint);
  }

  void _drawBrush(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill;
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.size / 2, paint);
      return;
    }
    final outline = getStroke(
      stroke.points.map((p) => PointVector(p.dx, p.dy)).toList(),
      options: StrokeOptions(size: stroke.size, thinning: 0.7, smoothing: 0.5, streamline: 0.5, simulatePressure: true),
    );
    if (outline.isEmpty) return;
    canvas.drawPath(outlinePath(outline), paint);
  }

  void _drawPencil(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    final points = stroke.points;

    if (pencilProgram != null) {
      _drawPencilWithShader(canvas, stroke);
      return;
    }

    // shader 미로드 시 fallback: 그레인 파티클 방식
    if (points.length == 1) {
      canvas.drawCircle(points[0], stroke.size * 0.45, Paint()
        ..color = stroke.color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0));
      return;
    }
    canvas.drawPath(smoothPath(points), Paint()
      ..color = stroke.color.withValues(alpha: 0.55)
      ..strokeWidth = stroke.size * 0.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke);
    final half = stroke.size / 2;
    final grainPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i += 2) {
      final p = points[i];
      final seed = (i * 31 + (p.dx * 13).round() + (p.dy * 17).round()).abs();
      final rng = math.Random(seed);
      final count = 3 + rng.nextInt(3);
      for (int j = 0; j < count; j++) {
        final dx = (rng.nextDouble() * 2 - 1) * half;
        final dy = (rng.nextDouble() * 2 - 1) * half;
        if (dx * dx + dy * dy > half * half) continue;
        final a = 0.08 + rng.nextDouble() * 0.28;
        final r = stroke.size * (0.04 + rng.nextDouble() * 0.08);
        grainPaint.color = stroke.color.withValues(alpha: a);
        canvas.drawCircle(Offset(p.dx + dx, p.dy + dy), r, grainPaint);
      }
    }
  }

  // ── 색연필: Fragment Shader로 Value Noise 기반 결 텍스처 렌더링 ──────────
  void _drawPencilWithShader(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    // stroke마다 새 shader 인스턴스를 생성해야 uniform 값이 독립적으로 유지됨.
    final shader = pencilProgram!.fragmentShader();
    final points = stroke.points;

    if (points.length == 1) {
      canvas.drawCircle(points[0], stroke.size * 0.45, Paint()
        ..color = stroke.color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill);
      return;
    }

    final outline = getStroke(
      points.map((p) => PointVector(p.dx, p.dy)).toList(),
      options: StrokeOptions(
        size: stroke.size * 0.8,
        thinning: 0.4,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: true,
      ),
    );
    if (outline.isEmpty) return;

    shader.setFloat(0, stroke.size);
    final c = stroke.color;
    final a = c.a;
    shader.setFloat(1, c.r * a);
    shader.setFloat(2, c.g * a);
    shader.setFloat(3, c.b * a);
    shader.setFloat(4, a);

    canvas.drawPath(outlinePath(outline), Paint()
      ..style = PaintingStyle.fill
      ..shader = shader);
  }

  void _drawEraser(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.size / 2, paint..style = PaintingStyle.fill);
      return;
    }
    canvas.drawPath(smoothPath(stroke.points), paint);
  }

  // ── 무지개 붓 ────────────────────────────────────────────
  void _drawRainbow(Canvas canvas, RainbowStroke stroke) {
    if (stroke.points.isEmpty) return;
    if (stroke.tool == DrawingTool.brush) {
      _drawRainbowBrush(canvas, stroke);
      return;
    }
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.size / 2, Paint()
        ..color = stroke.colors.isNotEmpty ? stroke.colors[0] : const Color(0xFFFF0000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma)
        ..style = PaintingStyle.fill);
      return;
    }
    // StrokeCap.round 캡 겹침 문제(Flutter #132436) 방지:
    // 세그먼트는 butt 캡으로, 시작·끝에만 원형 캡 수동 추가.
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];
      if ((p1 - p0).distance < 0.5) continue;

      final c0 = i < stroke.colors.length ? stroke.colors[i] : stroke.colors.last;
      final c1 = (i + 1) < stroke.colors.length ? stroke.colors[i + 1] : c0;

      final paint = Paint()
        ..strokeWidth = stroke.size
        ..strokeCap = stroke.blurSigma > 0 ? StrokeCap.square : StrokeCap.round
        ..style = PaintingStyle.stroke
        ..shader = ui.Gradient.linear(p0, p1, [c0, c1]);
      if (stroke.blurSigma > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma);
      }
      canvas.drawLine(p0, p1, paint);
    }

    final startColor = stroke.colors.isNotEmpty ? stroke.colors[0] : const Color(0xFFFF0000);
    final startCapPaint = Paint()..color = startColor..style = PaintingStyle.fill;
    if (stroke.blurSigma > 0) startCapPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma);
    canvas.drawCircle(stroke.points.first, stroke.size / 2, startCapPaint);

    final endColor = stroke.colors.isNotEmpty ? stroke.colors.last : startColor;
    final endCapPaint = Paint()..color = endColor..style = PaintingStyle.fill;
    if (stroke.blurSigma > 0) endCapPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma);
    canvas.drawCircle(stroke.points.last, stroke.size / 2, endCapPaint);
  }

  void _drawRainbowBrush(Canvas canvas, RainbowStroke stroke) {
    final points = stroke.points;
    final colors = stroke.colors;
    final N = points.length;
    if (N == 0) return;
    if (N == 1) {
      final color = colors.isNotEmpty ? colors[0] : const Color(0xFFFF0000);
      canvas.drawCircle(points[0], stroke.size / 2, Paint()..color = color..style = PaintingStyle.fill);
      return;
    }
    final dists = List.generate(N - 1, (i) => (points[i + 1] - points[i]).distance);
    final smoothDists = List<double>.generate(N - 1, (i) {
      int count = 1;
      double sum = dists[i];
      if (i > 0) { sum += dists[i - 1]; count++; }
      if (i < N - 2) { sum += dists[i + 1]; count++; }
      return sum / count;
    });
    final maxDist = smoothDists.reduce((a, b) => a > b ? a : b);
    for (int i = 0; i < N - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      if ((p1 - p0).distance < 0.5) continue;
      final normalizedSpeed = maxDist > 0 ? smoothDists[i] / maxDist : 0.5;
      final pressure = 1.0 - normalizedSpeed * 0.7;
      final width = stroke.size * (0.3 + pressure * 0.7);
      final c0 = i < colors.length ? colors[i] : colors.last;
      final c1 = (i + 1) < colors.length ? colors[i + 1] : c0;
      canvas.drawLine(p0, p1, Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..shader = ui.Gradient.linear(p0, p1, [c0, c1]));
    }
  }

  // ── 꽃씨 붓 ─────────────────────────────────────────────
  void _drawSparkleElement(Canvas canvas, SparkleElement element) {
    for (final obj in element.objects) {
      drawSparkleObject(canvas, obj);
    }
  }

  // ── 보조 ────────────────────────────────────────────────
  Path smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  Path outlinePath(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    if (points.length > 1) path.lineTo(points.last.dx, points.last.dy);
    path.close();
    return path;
  }
}
