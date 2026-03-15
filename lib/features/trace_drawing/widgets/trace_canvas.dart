import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_hitzone.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/painters/stroke_painter_mixin.dart';

/// 가이드 선 + 히트존 + 사용자 스트로크 캔버스.
/// [illustrationOpacity] : 배경 컬러 일러스트 투명도 (0.0~1.0, 기본 0.1)
/// [strokesOpacity]      : 가이드/히트존/스트로크 투명도 (0.0~1.0, 기본 1.0)
class TraceCanvas extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) => onSizeChanged(size));

        final illRect = template.completionRect(size);

        return GestureDetector(
          onPanStart: (d) => onPanStart(d.localPosition),
          onPanUpdate: (d) => onPanUpdate(d.localPosition),
          onPanEnd: (_) => onPanEnd(),
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
                  opacity: illustrationOpacity.clamp(0.0, 1.0),
                  child: SvgPicture.asset(template.svgAsset, fit: BoxFit.fill),
                ),
              ),

              // 3. 가이드선 + 히트존 + 스트로크 (완성 시 fade-out)
              Opacity(
                opacity: strokesOpacity.clamp(0.0, 1.0),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _TracePainter(
                      template: template,
                      elements: elements,
                      currentElement: currentElement,
                      hitZone: hitZone,
                      coverageVersion: coverageVersion,
                      canvasSize: size,
                      pencilProgram: pencilProgram,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
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
  final HitZone? hitZone;
  final int coverageVersion;
  final Size canvasSize;
  @override
  final ui.FragmentProgram? pencilProgram;

  const _TracePainter({
    required this.template,
    required this.elements,
    required this.currentElement,
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
    if (currentElement != null) drawElement(canvas, currentElement!);
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

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.template != template ||
      old.elements != elements ||
      old.currentElement != currentElement ||
      old.hitZone != hitZone ||
      old.coverageVersion != coverageVersion ||
      old.pencilProgram != pencilProgram;
}
