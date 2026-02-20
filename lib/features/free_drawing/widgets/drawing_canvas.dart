import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';

/// 터치 제스처를 받아 스트로크를 그리는 캔버스 위젯.
/// 실제 렌더링은 [_CanvasPainter]가 담당.
class DrawingCanvas extends StatelessWidget {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Color backgroundColor;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final VoidCallback onPanEnd;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    this.currentStroke,
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
            strokes: strokes,
            currentStroke: currentStroke,
            backgroundColor: backgroundColor,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// CustomPainter: 배경 + 모든 완료 스트로크 + 현재 그리는 스트로크 렌더링.
class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Color backgroundColor;

  const _CanvasPainter({
    required this.strokes,
    required this.currentStroke,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 5.1 배경 그리기
    canvas.drawRect(rect, Paint()..color = backgroundColor);

    // 스트로크 레이어: BlendMode.clear(지우개)가 동작하려면 saveLayer 필요
    canvas.saveLayer(rect, Paint());

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    switch (stroke.tool) {
      case DrawingTool.pen:
        _drawPen(canvas, stroke); // 5.2
      case DrawingTool.brush:
        _drawBrush(canvas, stroke); // 5.3
      case DrawingTool.pencil:
        _drawPencil(canvas, stroke); // 5.4
      case DrawingTool.eraser:
        _drawEraser(canvas, stroke); // 5.5
    }
  }

  // ── 5.2 펜: 일정한 굵기 ────────────────────────────────
  void _drawPen(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.size / 2,
          paint..style = PaintingStyle.fill);
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  // ── 5.3 붓: perfect_freehand 필압 효과 ────────────────
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

  // ── 5.4 색연필: 반투명 + 살짝 번짐 질감 ─────────────────
  void _drawPencil(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: 0.65)
      ..strokeWidth = stroke.size * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.size / 2,
          paint..style = PaintingStyle.fill);
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  // ── 5.5 지우개: BlendMode.clear ───────────────────────
  void _drawEraser(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points[0], stroke.size / 2,
          paint..style = PaintingStyle.fill);
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  // ── 보조: 부드러운 선 경로 (2차 베지어) ─────────────────
  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  // ── 보조: 외곽선 포인트 → 채울 Path ────────────────────
  Path _outlinePath(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    if (points.length > 1) {
      path.lineTo(points.last.dx, points.last.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.strokes != strokes ||
      old.currentStroke != currentStroke ||
      old.backgroundColor != backgroundColor;
}
