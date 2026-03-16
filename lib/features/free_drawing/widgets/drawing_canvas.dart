import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/painters/stroke_painter_mixin.dart';

/// 터치 제스처를 받아 DrawingElement 목록을 그리는 캔버스 위젯.
/// 두 손가락 핀치로 최대 2배까지 확대/이동 가능.
class DrawingCanvas extends StatefulWidget {
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
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  static const double _maxScale = 2.0;

  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // 제스처 시작 시점 스냅샷
  double _scaleOnStart = 1.0;
  Offset _offsetOnStart = Offset.zero;
  Offset _focalOnStart = Offset.zero;

  bool _isDrawing = false;

  /// 화면 좌표 → 캔버스 좌표 변환
  Offset _toCanvas(Offset screenPt) => (screenPt - _offset) / _scale;

  /// 줌 범위 이탈 방지
  void _clampOffset(Size size) {
    if (_scale <= 1.0) {
      _scale = 1.0;
      _offset = Offset.zero;
      return;
    }
    _offset = Offset(
      _offset.dx.clamp(size.width * (1.0 - _scale), 0.0),
      _offset.dy.clamp(size.height * (1.0 - _scale), 0.0),
    );
  }

  void _onScaleStart(ScaleStartDetails d) {
    _scaleOnStart = _scale;
    _offsetOnStart = _offset;
    _focalOnStart = d.localFocalPoint;

    if (d.pointerCount >= 2) {
      _isDrawing = false;
    } else {
      _isDrawing = true;
      widget.onPanStart(_toCanvas(d.localFocalPoint));
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size size) {
    if (d.pointerCount >= 2) {
      // 그리던 중 두 번째 손가락이 닿으면 stroke 취소
      if (_isDrawing) {
        widget.onPanEnd();
        _isDrawing = false;
      }
      setState(() {
        final newScale = (_scaleOnStart * d.scale).clamp(1.0, _maxScale);
        // 핀치 중심(캔버스 좌표)이 화면 focal point에 고정되도록 offset 계산
        final focalInCanvas = (_focalOnStart - _offsetOnStart) / _scaleOnStart;
        _scale = newScale;
        _offset = d.localFocalPoint - focalInCanvas * newScale;
        _clampOffset(size);
      });
    } else if (_isDrawing) {
      widget.onPanUpdate(_toCanvas(d.localFocalPoint));
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_isDrawing) widget.onPanEnd();
    _isDrawing = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: (d) => _onScaleUpdate(d, size),
          onScaleEnd: _onScaleEnd,
          child: ClipRect(
            child: Transform.translate(
              offset: _offset,
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _CanvasPainter(
                      elements: widget.elements,
                      currentElement: widget.currentElement,
                      backgroundColor: widget.backgroundColor,
                      pencilProgram: widget.pencilProgram,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
