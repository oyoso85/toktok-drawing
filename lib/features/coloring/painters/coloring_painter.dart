import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/coloring/animations/fill_animation_painter.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';

/// 색칠 캔버스 CustomPainter.
/// - 미채움 인터랙티브 path: 흰색 fill + 검정 stroke + hintOpacity 힌트 색상
/// - 채워진 path: 사용자가 선택한 색상 (filledPaths[index])
/// - 소형/흰색 path: SVG 원본 fill 색상 (항상)
/// - 진행 중 애니메이션: targetPath 위에 클리핑되어 렌더
class ColoringPainter extends CustomPainter {
  final List<ColoringPath> paths;
  final Map<int, Color> filledPaths;

  /// 미채움 단면에 원본 색을 얼마나 비쳐 보이게 할지 (0.0 ~ 0.10).
  final double hintOpacity;

  final FillAnimationPainter? activeAnimation;
  final ui.Path? animationTargetPath;
  final Color? animationFillColor;
  final Offset? animationTapOffset;
  final double animationT;
  final Float64List? transformMatrix;

  const ColoringPainter({
    required this.paths,
    required this.filledPaths,
    this.hintOpacity = 0.0,
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
      // 흰색·검정 면: 처음부터 원본 색으로 채워진 상태 (탭 불가)
      if (cp.isWhite || cp.isBlack) {
        canvas.drawPath(cp.path, Paint()
          ..color = cp.fillColor
          ..style = PaintingStyle.fill);
        continue;
      }

      final filledColor = filledPaths[cp.index];
      if (filledColor != null) {
        // 채워진 path: 사용자가 선택한 색상
        canvas.drawPath(cp.path, Paint()
          ..color = filledColor
          ..style = PaintingStyle.fill);
        canvas.drawPath(cp.path, strokePaint);
      } else {
        // 미채움 interactive path: 흰색 fill + 검정 테두리
        canvas.drawPath(cp.path, whitePaint);
        if (cp.isInteractive && hintOpacity > 0.0) {
          canvas.drawPath(
            cp.path,
            Paint()
              ..color = cp.fillColor.withValues(alpha: hintOpacity)
              ..style = PaintingStyle.fill,
          );
        }
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
      old.hintOpacity != hintOpacity ||
      old.animationT != animationT ||
      old.activeAnimation != activeAnimation;
}
