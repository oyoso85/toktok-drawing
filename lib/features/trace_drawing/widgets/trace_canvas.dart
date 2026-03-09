import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';

/// 6.3 + 6.4 가이드 선 + 사용자 스트로크 캔버스.
/// - 하단 레이어: 가이드 선 (연한 회색 점선)
/// - 상단 레이어: 사용자가 그린 스트로크
class TraceCanvas extends StatelessWidget {
  final TraceTemplate template;
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final VoidCallback onPanEnd;

  const TraceCanvas({
    super.key,
    required this.template,
    required this.strokes,
    this.currentStroke,
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
          painter: _TracePainter(
            template: template,
            strokes: strokes,
            currentStroke: currentStroke,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final TraceTemplate template;
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  const _TracePainter({
    required this.template,
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 6.3 가이드 선: 흰 배경 → 점선 가이드
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );
    _drawGuide(canvas, size);

    // 6.4 사용자 스트로크 오버레이
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final s in strokes) {
      _drawStroke(canvas, s);
    }
    if (currentStroke != null) _drawStroke(canvas, currentStroke!);
    canvas.restore();
  }

  /// 6.3 가이드 선: 연한 회색 점선 (dashPattern: on=12, off=8)
  void _drawGuide(Canvas canvas, Size size) {
    final guidePath = template.pathBuilder(size);
    final paint = Paint()
      ..color = const Color(0xFFC8C8C8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _drawDashedPath(canvas, guidePath, paint, dashLength: 14, gapLength: 8);

    // 시작점 원형 마커
    _drawStartMarker(canvas, guidePath);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final len = drawing ? dashLength : gapLength;
        if (drawing) {
          final extracted = metric.extractPath(
            distance,
            (distance + len).clamp(0, metric.length),
          );
          canvas.drawPath(extracted, paint);
        }
        distance += len;
        drawing = !drawing;
      }
    }
  }

  void _drawStartMarker(Canvas canvas, Path guidePath) {
    final metrics = guidePath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final tangent = metrics.first.getTangentForOffset(0);
    if (tangent == null) return;
    canvas.drawCircle(
      tangent.position,
      10,
      Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      tangent.position,
      10,
      Paint()
        ..color = const Color(0xFF4CAF50)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  // ── 사용자 스트로크 렌더링 (free_drawing 동일 로직) ─────

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
      canvas.drawCircle(
          stroke.points[0], stroke.size / 2, paint..style = PaintingStyle.fill);
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
      options: StrokeOptions(
        size: stroke.size,
        thinning: 0.7,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: true,
      ),
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
      canvas.drawCircle(
          stroke.points[0], stroke.size / 2, paint..style = PaintingStyle.fill);
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  void _drawEraser(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (stroke.points.length == 1) {
      canvas.drawCircle(
          stroke.points[0], stroke.size / 2, paint..style = PaintingStyle.fill);
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

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
  bool shouldRepaint(_TracePainter old) =>
      old.template != template ||
      old.strokes != strokes ||
      old.currentStroke != currentStroke;
}
