import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/rainbow_stroke.dart';
import 'package:toktok_drawing/shared/painters/stroke_painter_mixin.dart';

/// 터치 제스처를 받아 DrawingElement 목록을 그리는 캔버스 위젯.
/// 두 손가락 핀치로 최대 2배까지 확대/이동 가능.
///
/// 성능 최적화:
/// - 완성된 strokes → ui.Picture로 굽기(O(1) 재렌더)
/// - 현재 무지개 stroke → 새 세그먼트만 누적 캐시, 끝 캡만 재렌더
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

  // ── 줌 상태 ────────────────────────────────────────────
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _scaleOnStart = 1.0;
  Offset _offsetOnStart = Offset.zero;
  Offset _focalOnStart = Offset.zero;
  bool _isDrawing = false;

  // ── 렌더링 캐시 ────────────────────────────────────────
  /// 완성된 elements 전체를 구운 Picture. endStroke/undo/redo 시에만 재빌드.
  ui.Picture? _completedPicture;
  int _completedCount = 0; // _completedPicture에 포함된 elements 수

  /// 현재 그리는 무지개 stroke의 누적 세그먼트 Picture.
  /// 새 세그먼트만 incremental하게 추가 — 끝 캡은 매 프레임 painter가 직접 그림.
  ui.Picture? _rainbowPicture;
  int _rainbowSegCount = 0; // _rainbowPicture에 포함된 세그먼트 수

  // ── 라이프사이클 ────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _updateCompletedPicture();
  }

  @override
  void didUpdateWidget(DrawingCanvas old) {
    super.didUpdateWidget(old);
    // elements가 바뀌었을 때만 completed picture 재빌드
    if (!identical(widget.elements, old.elements) ||
        widget.pencilProgram != old.pencilProgram ||
        widget.backgroundColor != old.backgroundColor) {
      _updateCompletedPicture();
    }
    // currentElement가 바뀌었을 때 rainbow cache 업데이트
    if (!identical(widget.currentElement, old.currentElement)) {
      _updateRainbowCache();
    }
  }

  @override
  void dispose() {
    _completedPicture?.dispose();
    _rainbowPicture?.dispose();
    super.dispose();
  }

  // ── 캐시 빌드 ──────────────────────────────────────────

  /// 완성된 elements를 Picture로 굽는다.
  /// - elements 추가(endStroke): 기존 Picture에 새 element만 그려 incremental 빌드
  /// - elements 감소(undo/clear): 처음부터 전체 재빌드
  void _updateCompletedPicture() {
    final elements = widget.elements;
    if (elements.length == _completedCount && _completedPicture != null) return;

    if (elements.isEmpty) {
      _completedPicture?.dispose();
      _completedPicture = null;
      _completedCount = 0;
      return;
    }

    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final renderer = _Renderer(widget.pencilProgram);

    if (elements.length > _completedCount && _completedPicture != null) {
      // Incremental: 기존 그림 위에 새 element만 추가
      c.drawPicture(_completedPicture!);
      for (int i = _completedCount; i < elements.length; i++) {
        renderer.drawElement(c, elements[i]);
      }
    } else {
      // Full rebuild (undo/redo/clear 등)
      for (final el in elements) {
        renderer.drawElement(c, el);
      }
    }

    _completedPicture?.dispose();
    _completedPicture = recorder.endRecording();
    _completedCount = elements.length;
  }

  /// 현재 그리는 무지개 stroke의 새 세그먼트를 Picture에 누적한다.
  /// 붓(brush) 변형은 속도 기반 굵기 계산 때문에 캐시 불가 → 그대로 painter에 위임.
  void _updateRainbowCache() {
    final current = widget.currentElement;

    // 무지개 pen이 아니면 캐시 해제
    if (current is! RainbowStroke || current.tool == DrawingTool.brush) {
      _rainbowPicture?.dispose();
      _rainbowPicture = null;
      _rainbowSegCount = 0;
      return;
    }

    final targetSeg = current.points.length - 1; // 그려야 할 세그먼트 수

    // 포인트가 줄었다 = 새 stroke 시작 → 캐시 리셋
    if (targetSeg < _rainbowSegCount) {
      _rainbowPicture?.dispose();
      _rainbowPicture = null;
      _rainbowSegCount = 0;
    }

    if (targetSeg <= _rainbowSegCount) return; // 새 세그먼트 없음

    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);

    if (_rainbowSegCount == 0) {
      // 첫 배치: 시작 캡을 Picture에 포함
      final startColor = current.colors.isNotEmpty ? current.colors[0] : const Color(0xFFFF0000);
      final capPaint = Paint()..color = startColor..style = PaintingStyle.fill;
      if (current.blurSigma > 0) {
        capPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, current.blurSigma);
      }
      c.drawCircle(current.points.first, current.size / 2, capPaint);
    } else {
      // 기존 Picture 위에 새 세그먼트 추가
      c.drawPicture(_rainbowPicture!);
    }

    // 새 세그먼트만 그리기
    final segPaint = Paint()
      ..strokeWidth = current.size
      ..strokeCap = current.blurSigma > 0 ? StrokeCap.square : StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (current.blurSigma > 0) {
      segPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, current.blurSigma);
    }

    for (int i = _rainbowSegCount; i < targetSeg; i++) {
      final p0 = current.points[i];
      final p1 = current.points[i + 1];
      if ((p1 - p0).distance < 0.5) continue;
      final c0 = i < current.colors.length ? current.colors[i] : current.colors.last;
      final c1 = (i + 1) < current.colors.length ? current.colors[i + 1] : c0;
      segPaint.shader = ui.Gradient.linear(p0, p1, [c0, c1]);
      c.drawLine(p0, p1, segPaint);
    }

    _rainbowPicture?.dispose();
    _rainbowPicture = recorder.endRecording();
    _rainbowSegCount = targetSeg;
  }

  // ── 좌표 변환 ──────────────────────────────────────────
  Offset _toCanvas(Offset screenPt) => (screenPt - _offset) / _scale;

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

  // ── 제스처 핸들러 ──────────────────────────────────────
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
      if (_isDrawing) {
        widget.onPanEnd();
        _isDrawing = false;
      }
      setState(() {
        final newScale = (_scaleOnStart * d.scale).clamp(1.0, _maxScale);
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

  // ── 빌드 ──────────────────────────────────────────────
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
                      completedPicture: _completedPicture,
                      currentElement: widget.currentElement,
                      rainbowPicture: _rainbowPicture,
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

// ── StrokePainterMixin을 standalone으로 사용하기 위한 헬퍼 ──
class _Renderer with StrokePainterMixin {
  @override
  final ui.FragmentProgram? pencilProgram;
  _Renderer(this.pencilProgram);
}

// ── CustomPainter ──────────────────────────────────────
class _CanvasPainter extends CustomPainter with StrokePainterMixin {
  /// 완성된 모든 strokes를 구운 Picture (null = 아직 없음)
  final ui.Picture? completedPicture;
  final DrawingElement? currentElement;
  /// 현재 무지개 stroke의 누적 세그먼트 Picture (끝 캡 제외)
  final ui.Picture? rainbowPicture;
  final Color backgroundColor;
  @override
  final ui.FragmentProgram? pencilProgram;

  const _CanvasPainter({
    required this.completedPicture,
    required this.currentElement,
    required this.rainbowPicture,
    required this.backgroundColor,
    this.pencilProgram,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = backgroundColor);

    // 완성된 strokes: saveLayer 밖에서 drawPicture → GPU 텍스처 캐시 유지, O(1)
    if (completedPicture != null) canvas.drawPicture(completedPicture!);

    // 현재 그리는 element만 saveLayer (지우개 BlendMode.clear 지원)
    final current = currentElement;
    if (current != null) {
      canvas.saveLayer(rect, Paint());
      if (current is RainbowStroke &&
          current.tool != DrawingTool.brush &&
          rainbowPicture != null) {
        canvas.drawPicture(rainbowPicture!);
        _drawEndCap(canvas, current);
      } else {
        drawElement(canvas, current);
      }
      canvas.restore();
    }
  }

  /// 끝 캡: 매 프레임 마지막 포인트 색상으로 재렌더
  void _drawEndCap(Canvas canvas, RainbowStroke stroke) {
    if (stroke.points.isEmpty) return;
    final color = stroke.colors.isNotEmpty ? stroke.colors.last : const Color(0xFFFF0000);
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    if (stroke.blurSigma > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma);
    }
    canvas.drawCircle(stroke.points.last, stroke.size / 2, paint);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      !identical(old.completedPicture, completedPicture) ||
      !identical(old.currentElement, currentElement) ||
      !identical(old.rainbowPicture, rainbowPicture) ||
      old.backgroundColor != backgroundColor ||
      old.pencilProgram != pencilProgram;
}
