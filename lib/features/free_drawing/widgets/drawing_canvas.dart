import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/painters/stroke_painter_mixin.dart';

/// 터치 제스처를 받아 DrawingElement 목록을 그리는 캔버스 위젯.
class DrawingCanvas extends StatelessWidget {
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final Color backgroundColor;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final VoidCallback onPanEnd;
  final ui.FragmentProgram? pencilProgram;

  const DrawingCanvas({
    super.key,
    required this.elements,
    this.currentElement,
    required this.backgroundColor,
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
          painter: _CanvasPainter(
            elements: elements,
            currentElement: currentElement,
            backgroundColor: backgroundColor,
            pencilProgram: pencilProgram,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter with StrokePainterMixin {
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final Color backgroundColor;
  @override
  final ui.FragmentProgram? pencilProgram;

  const _CanvasPainter({
    required this.elements,
    required this.currentElement,
    required this.backgroundColor,
    this.pencilProgram,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = backgroundColor);
    canvas.saveLayer(rect, Paint());
    for (final el in elements) {
      drawElement(canvas, el);
    }
    if (currentElement != null) drawElement(canvas, currentElement!);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.elements != elements ||
      old.currentElement != currentElement ||
      old.backgroundColor != backgroundColor ||
      old.pencilProgram != pencilProgram;
}
