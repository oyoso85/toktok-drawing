import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/painters/stroke_painter_mixin.dart';

/// 6.3 + 6.4 가이드 선 + 사용자 스트로크 캔버스.
class TraceCanvas extends StatelessWidget {
  final TraceTemplate template;
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final VoidCallback onPanEnd;
  final ui.FragmentProgram? pencilProgram;

  const TraceCanvas({
    super.key,
    required this.template,
    required this.elements,
    this.currentElement,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.pencilProgram,
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
            elements: elements,
            currentElement: currentElement,
            pencilProgram: pencilProgram,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter with StrokePainterMixin {
  final TraceTemplate template;
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  @override
  final ui.FragmentProgram? pencilProgram;

  const _TracePainter({
    required this.template,
    required this.elements,
    required this.currentElement,
    this.pencilProgram,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    _drawGuide(canvas, size);

    canvas.saveLayer(Offset.zero & size, Paint());
    for (final el in elements) {
      drawElement(canvas, el);
    }
    if (currentElement != null) drawElement(canvas, currentElement!);
    canvas.restore();
  }

  void _drawGuide(Canvas canvas, Size size) {
    final guidePath = template.pathBuilder(size);
    final paint = Paint()
      ..color = const Color(0xFFC8C8C8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    _drawDashedPath(canvas, guidePath, paint, dashLength: 14, gapLength: 8);
    _drawStartMarker(canvas, guidePath);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {required double dashLength, required double gapLength}) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final len = drawing ? dashLength : gapLength;
        if (drawing) {
          canvas.drawPath(
            metric.extractPath(distance, (distance + len).clamp(0, metric.length)),
            paint,
          );
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
    canvas.drawCircle(tangent.position, 10,
        Paint()..color = const Color(0xFF4CAF50).withValues(alpha: 0.7)..style = PaintingStyle.fill);
    canvas.drawCircle(tangent.position, 10,
        Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.template != template ||
      old.elements != elements ||
      old.currentElement != currentElement ||
      old.pencilProgram != pencilProgram;
}
