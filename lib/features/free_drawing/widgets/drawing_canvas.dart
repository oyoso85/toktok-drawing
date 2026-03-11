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
    if (stroke.points.isEmpty) return;
    final points = stroke.points;

    if (points.length == 1) {
      canvas.drawCircle(points[0], stroke.size * 0.45, Paint()
        ..color = stroke.color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0));
      return;
    }

    // 1. 베이스 획: 반투명 + 살짝 가늘게
    canvas.drawPath(_smoothPath(points), Paint()
      ..color = stroke.color.withValues(alpha: 0.55)
      ..strokeWidth = stroke.size * 0.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke);

    // 2. 그레인 파티클: 경로 주변에 작은 점 산포 → 색연필 결 표현
    // 위치 + 인덱스 기반 결정론적 시드로 리렌더 시 깜빡임 방지
    final half = stroke.size / 2;
    final grainPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i += 2) {
      final p = points[i];
      final seed = (i * 31 + (p.dx * 13).round() + (p.dy * 17).round()).abs();
      final rng = math.Random(seed);
      final count = 3 + rng.nextInt(3); // 3~5개
      for (int j = 0; j < count; j++) {
        final dx = (rng.nextDouble() * 2 - 1) * half;
        final dy = (rng.nextDouble() * 2 - 1) * half;
        if (dx * dx + dy * dy > half * half) continue; // 원 영역으로 제한
        final a = 0.08 + rng.nextDouble() * 0.28;
        final r = stroke.size * (0.04 + rng.nextDouble() * 0.08);
        grainPaint.color = stroke.color.withValues(alpha: a);
        canvas.drawCircle(Offset(p.dx + dx, p.dy + dy), r, grainPaint);
      }
    }
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
    // 붓 도구는 perfect_freehand로 속도 기반 굵기 변화 유지
    if (stroke.tool == DrawingTool.brush) {
      _drawRainbowBrush(canvas, stroke);
      return;
    }
    if (stroke.points.length == 1) {
      final paint = Paint()
        ..color = stroke.colors.isNotEmpty ? stroke.colors[0] : const Color(0xFFFF0000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(stroke.points[0], stroke.size / 2, paint);
      return;
    }
    // StrokeCap.round 캡이 인접 세그먼트 공유 포인트에서 2개 겹쳐
    // 두 배로 밝아지는 문제(Flutter issue #132436) 방지:
    // 세그먼트는 StrokeCap.butt으로 그려 캡을 제거하고,
    // 획의 시작·끝 포인트에만 원형 캡을 수동으로 그린다.
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];
      if ((p1 - p0).distance < 0.5) continue;

      final c0 = i < stroke.colors.length ? stroke.colors[i] : stroke.colors.last;
      final c1 = (i + 1) < stroke.colors.length ? stroke.colors[i + 1] : c0;

      // blur 있을 때: square 캡으로 junction 공백 방지 (round는 blur 겹침으로 밝은 점 발생)
      // blur 없을 때: round 캡 사용 (불투명 색은 srcOver로 덮어쓰므로 겹침 문제 없음)
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

    // 시작점 원형 캡
    final startColor = stroke.colors.isNotEmpty ? stroke.colors[0] : const Color(0xFFFF0000);
    final startCapPaint = Paint()
      ..color = startColor
      ..style = PaintingStyle.fill;
    if (stroke.blurSigma > 0) {
      startCapPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma);
    }
    canvas.drawCircle(stroke.points.first, stroke.size / 2, startCapPaint);
    // 끝점 원형 캡
    final endColor = stroke.colors.isNotEmpty ? stroke.colors.last : startColor;
    final endCapPaint = Paint()
      ..color = endColor
      ..style = PaintingStyle.fill;
    if (stroke.blurSigma > 0) {
      endCapPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma);
    }
    canvas.drawCircle(stroke.points.last, stroke.size / 2, endCapPaint);
  }

  // ── 무지개 붓(붓 도구): 세그먼트별 시간 기반 색상 + 속도 기반 굵기 ──────
  // perfect_freehand 아웃라인 대신 세그먼트 단위 drawLine을 사용해
  // 펜처럼 색상이 그릴 때마다 누적되도록 한다.
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

    // 인접 포인트 간 거리 계산
    final dists = List.generate(N - 1, (i) => (points[i + 1] - points[i]).distance);

    // 거리 3점 이동평균으로 스무딩 (급격한 굵기 변화 방지)
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

      // 느리게 = 두껍게, 빠르게 = 얇게 (thinning 0.7)
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
