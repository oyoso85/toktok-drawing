import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/rainbow_stroke.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_shape_painter.dart';

/// 터치 제스처를 받아 DrawingElement 목록을 그리는 캔버스 위젯.
class DrawingCanvas extends StatelessWidget {
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final Color backgroundColor;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final VoidCallback onPanEnd;

  const DrawingCanvas({
    super.key,
    required this.elements,
    this.currentElement,
    required this.backgroundColor,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => onPanStart(d.localPosition),
      onPanUpdate: (d) => onPanUpdate(d.localPosition),
      onPanEnd: (_) => onPanEnd(),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CanvasPainter(
            elements: elements,
            currentElement: currentElement,
            backgroundColor: backgroundColor,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final Color backgroundColor;

  const _CanvasPainter({
    required this.elements,
    required this.currentElement,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = backgroundColor);

    canvas.saveLayer(rect, Paint());
    for (final el in elements) {
      _drawElement(canvas, el);
    }
    if (currentElement != null) {
      _drawElement(canvas, currentElement!);
    }
    canvas.restore();
  }

  void _drawElement(Canvas canvas, DrawingElement el) {
    if (el is Stroke) {
      _drawStroke(canvas, el);
    } else if (el is RainbowStroke) {
      _drawRainbow(canvas, el);
    } else if (el is SparkleElement) {
      _drawSparkleElement(canvas, el);
    }
  }

  // ── 일반 Stroke ────────────────────────────────────────
  void _drawStroke(Canvas canvas, Stroke stroke) {
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
    canvas.drawPath(_smoothPath(stroke.points), paint);
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
    canvas.drawPath(_outlinePath(outline), paint);
  }

  void _drawPencil(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: 0.65)
      ..strokeWidth = stroke.size * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.size / 2, paint..style = PaintingStyle.fill);
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
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
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  // ── 무지개 붓: 포인트 간 그라데이션 세그먼트 ────────────────
  void _drawRainbow(Canvas canvas, RainbowStroke stroke) {
    if (stroke.points.isEmpty) return;
    if (stroke.points.length == 1) {
      final paint = Paint()
        ..color = stroke.colors.isNotEmpty ? stroke.colors[0] : const Color(0xFFFF0000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(stroke.points[0], stroke.size / 2, paint);
      return;
    }
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];
      if ((p1 - p0).distance < 0.5) continue;

      final c0 = i < stroke.colors.length ? stroke.colors[i] : stroke.colors.last;
      final c1 = (i + 1) < stroke.colors.length ? stroke.colors[i + 1] : c0;

      final paint = Paint()
        ..strokeWidth = stroke.size
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma)
        ..shader = ui.Gradient.linear(p0, p1, [c0, c1]);

      canvas.drawLine(p0, p1, paint);
    }
  }

  // ── 꽃씨 붓: 오브젝트 정적 렌더링 ──────────────────────────
  void _drawSparkleElement(Canvas canvas, SparkleElement element) {
    for (final obj in element.objects) {
      drawSparkleObject(canvas, obj);
    }
  }

  // ── 보조 ────────────────────────────────────────────────
  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  Path _outlinePath(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    if (points.length > 1) path.lineTo(points.last.dx, points.last.dy);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.elements != elements ||
      old.currentElement != currentElement ||
      old.backgroundColor != backgroundColor;
}
