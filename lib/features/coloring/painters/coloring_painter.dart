import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/coloring/animations/fill_animation_painter.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';

/// 색칠 캔버스 CustomPainter.
/// - 미채움 인터랙티브 path: 흰색 fill + 검정 stroke
/// - 채워진 path: SVG 원본 fill 색상
/// - 소형/흰색 path: SVG 원본 fill 색상 (항상)
/// - 진행 중 애니메이션: targetPath 위에 클리핑되어 렌더
class ColoringPainter extends CustomPainter {
  final List<ColoringPath> paths;
  final Set<int> filledPaths;
  final FillAnimationPainter? activeAnimation;
  final ui.Path? animationTargetPath;
  final Color? animationFillColor;
  final Offset? animationTapOffset;
  final double animationT;
  final Float64List? transformMatrix;

  const ColoringPainter({
    required this.paths,
    required this.filledPaths,
    this.activeAnimation,
    this.animationTargetPath,
    this.animationFillColor,
    this.animationTapOffset,
    this.animationT = 0.0,
    this.transformMatrix,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (transformMatrix != null) {
      canvas.save();
      canvas.transform(transformMatrix!);
    }

    final strokePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final cp in paths) {
      if (!cp.isInteractive) {
        // 소형/흰색 path: 처음부터 원본 색상으로 표시
        canvas.drawPath(cp.path, Paint()
          ..color = cp.fillColor
          ..style = PaintingStyle.fill);
        continue;
      }

      if (filledPaths.contains(cp.index)) {
        // 채워진 path: solid fill
        canvas.drawPath(cp.path, Paint()
          ..color = cp.fillColor
          ..style = PaintingStyle.fill);
        canvas.drawPath(cp.path, strokePaint);
      } else {
        // 미채움: 흰색 fill + 검정 테두리
        canvas.drawPath(cp.path, whitePaint);
        canvas.drawPath(cp.path, strokePaint);
      }
    }

    // 진행 중인 채우기 애니메이션
    if (activeAnimation != null &&
        animationTargetPath != null &&
        animationFillColor != null &&
        animationTapOffset != null) {
      activeAnimation!.paint(
        canvas,
        size,
        animationTargetPath!,
        animationFillColor!,
        animationT,
        animationTapOffset!,
      );
    }

    if (transformMatrix != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ColoringPainter old) =>
      old.filledPaths != filledPaths ||
      old.animationT != animationT ||
      old.activeAnimation != activeAnimation;
}
