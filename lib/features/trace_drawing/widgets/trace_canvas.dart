import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_hitzone.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/rainbow_stroke.dart';
import 'package:toktok_drawing/shared/painters/stroke_painter_mixin.dart';

/// 가이드 선 + 히트존 + 사용자 스트로크 캔버스.
/// [illustrationOpacity] : 배경 컬러 일러스트 투명도 (0.0~1.0, 기본 0.1)
/// [strokesOpacity]      : 가이드/히트존/스트로크 투명도 (0.0~1.0, 기본 1.0)
/// 두 손가락 핀치로 최대 2배까지 확대/이동 가능.
class TraceCanvas extends StatefulWidget {
  final TraceTemplate template;
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final HitZone? hitZone;
  final int coverageVersion;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final VoidCallback onPanEnd;
  final void Function(Size) onSizeChanged;
  final ui.FragmentProgram? pencilProgram;
  final double illustrationOpacity;
  final double strokesOpacity;

  const TraceCanvas({
    super.key,
    required this.template,
    required this.elements,
    this.currentElement,
    this.hitZone,
    this.coverageVersion = 0,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onSizeChanged,
    this.pencilProgram,
    this.illustrationOpacity = 0.1,
    this.strokesOpacity = 1.0,
  });

  @override
  State<TraceCanvas> createState() => _TraceCanvasState();
}

class _TraceCanvasState extends State<TraceCanvas> {
  static const double _maxScale = 2.0;

  // ── 줌 상태 ────────────────────────────────────────────
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _scaleOnStart = 1.0;
  Offset _offsetOnStart = Offset.zero;
  Offset _focalOnStart = Offset.zero;
  bool _isDrawing = false;

  // ── 무지개 세그먼트 누적 캐시 ──────────────────────────
  ui.Picture? _rainbowPicture;
  int _rainbowSegCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(TraceCanvas old) {
    super.didUpdateWidget(old);
    // 도안이 바뀌면 줌 + 무지개 캐시 리셋
    if (old.template != widget.template) {
      _scale = 1.0;
      _offset = Offset.zero;
      _rainbowPicture?.dispose();
      _rainbowPicture = null;
      _rainbowSegCount = 0;
    }
    if (!identical(widget.currentElement, old.currentElement)) {
      _updateRainbowCache();
    }
  }

  @override
  void dispose() {
    _rainbowPicture?.dispose();
    super.dispose();
  }

  void _updateRainbowCache() {
    final current = widget.currentElement;

    if (current is! RainbowStroke || current.tool == DrawingTool.brush) {
      _rainbowPicture?.dispose();
      _rainbowPicture = null;
      _rainbowSegCount = 0;
      return;
    }

    final targetSeg = current.points.length - 1;

    if (targetSeg < _rainbowSegCount) {
      _rainbowPicture?.dispose();
      _rainbowPicture = null;
      _rainbowSegCount = 0;
    }

    if (targetSeg <= _rainbowSegCount) return;

    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);

    if (_rainbowSegCount == 0) {
      final startColor = current.colors.isNotEmpty ? current.colors[0] : const Color(0xFFFF0000);
      final capPaint = Paint()..color = startColor..style = PaintingStyle.fill;
      if (current.blurSigma > 0) {
        capPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, current.blurSigma);
      }
      c.drawCircle(current.points.first, current.size / 2, capPaint);
    } else {
      c.drawPicture(_rainbowPicture!);
    }

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSizeChanged(size));

        final illRect = widget.template.completionRect(size);

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
              child: Stack(
                children: [
                  // 1. 흰 배경
                  const Positioned.fill(child: ColoredBox(color: Colors.white)),

                  // 2. 컬러 일러스트 (항상 표시, opacity 애니메이션)
                  Positioned(
                    left: illRect.left,
                    top: illRect.top,
                    width: illRect.width,
                    height: illRect.height,
                    child: Opacity(
                      opacity: widget.illustrationOpacity.clamp(0.0, 1.0),
                      child: SvgPicture.asset(widget.template.svgAsset, fit: BoxFit.fill),
                    ),
                  ),

                  // 3. 가이드선 + 히트존 + 스트로크 (완성 시 fade-out)
                  Opacity(
                    opacity: widget.strokesOpacity.clamp(0.0, 1.0),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _TracePainter(
                          template: widget.template,
                          elements: widget.elements,
                          currentElement: widget.currentElement,
                          rainbowPicture: _rainbowPicture,
                          hitZone: widget.hitZone,
                          coverageVersion: widget.coverageVersion,
                          canvasSize: size,
                          pencilProgram: widget.pencilProgram,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TracePainter extends CustomPainter with StrokePainterMixin {
  final TraceTemplate template;
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  /// 현재 무지개 stroke의 누적 세그먼트 Picture (끝 캡 제외)
  final ui.Picture? rainbowPicture;
  final HitZone? hitZone;
  final int coverageVersion;
  final Size canvasSize;
  @override
  final ui.FragmentProgram? pencilProgram;

  const _TracePainter({
    required this.template,
    required this.elements,
    required this.currentElement,
    this.rainbowPicture,
    this.hitZone,
    this.coverageVersion = 0,
    required this.canvasSize,
    this.pencilProgram,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경은 Stack의 ColoredBox가 담당하므로 여기서는 투명하게 유지

    // 1. 히트존 — 미커버 세그먼트만 노란 반투명 원
    _drawHitZone(canvas);

    // 2. 가이드 점선
    _drawGuide(canvas, size);

    // 3. 사용자 스트로크 — 히트존 영역에만 클리핑
    final hz = hitZone;
    canvas.save();
    if (hz != null && hz.segments.isNotEmpty) {
      canvas.clipPath(hz.buildClipPath());
    }
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final el in elements) {
      drawElement(canvas, el);
    }
    final current = currentElement;
    if (current != null) {
      if (current is RainbowStroke &&
          current.tool != DrawingTool.brush &&
          rainbowPicture != null) {
        canvas.drawPicture(rainbowPicture!);
        _drawEndCap(canvas, current);
      } else {
        drawElement(canvas, current);
      }
    }
    canvas.restore();
    canvas.restore();
  }

  void _drawHitZone(Canvas canvas) {
    final hz = hitZone;
    if (hz == null || hz.segments.isEmpty) return;

    final uncoveredPaint = Paint()
      ..color = const Color(0x33FFD700)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < hz.segments.length; i++) {
      if (!hz.segmentCovered[i]) {
        canvas.drawCircle(hz.segments[i], hz.hitRadius, uncoveredPaint);
      }
    }
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
  bool shouldRepaint(_TracePainter old) =>
      old.template != template ||
      old.elements != elements ||
      old.currentElement != currentElement ||
      !identical(old.rainbowPicture, rainbowPicture) ||
      old.hitZone != hitZone ||
      old.coverageVersion != coverageVersion ||
      old.pencilProgram != pencilProgram;
}
