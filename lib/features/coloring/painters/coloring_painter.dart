import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/coloring/animations/active_fill_animation.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';

/// 색칠 캔버스 CustomPainter.
/// - 미채움 인터랙티브 path: 흰색 fill + 검정 stroke + hintOpacity 힌트 색상
/// - 채워진 path: 사용자가 선택한 색상 (filledPaths[index])
/// - 소형/흰색 path: SVG 원본 fill 색상 (항상)
/// - 진행 중 애니메이션: 각 targetPath 위에 클리핑되어 동시 렌더
class ColoringPainter extends CustomPainter {
  final List<ColoringPath> paths;
  final Map<int, Color> filledPaths;

  /// 미채움 단면에 원본 색을 얼마나 비쳐 보이게 할지 (0.0 ~ 0.10).
  final double hintOpacity;

  /// 외곽선(stroke) 불투명도. 완성 시 0.0으로 fade-out.
  final double strokeOpacity;

  final List<ActiveFillAnimation> activeAnimations;
  final Float64List? transformMatrix;

  const ColoringPainter({
    required this.paths,
    required this.filledPaths,
    this.hintOpacity = 0.0,
    this.strokeOpacity = 1.0,
    this.activeAnimations = const [],
    this.transformMatrix,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (transformMatrix != null) {
      canvas.save();
      canvas.transform(transformMatrix!);
    }

    // strokeWidth를 2배로 설정 후 내부를 fill로 덮어 외부 stroke만 보이게 함.
    // 결과: 좁은 path에서도 외부 1.5px 검정선만 보여 굵기가 일정하게 유지됨.
    final outerStrokePaint = Paint()
      ..color = Colors.black.withValues(alpha: strokeOpacity)
      ..strokeWidth = 3.0
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
      // stroke를 먼저 그린 후 fill로 내부를 덮어 outer stroke 효과 적용
      canvas.drawPath(cp.path, outerStrokePaint);
      if (filledColor != null) {
        // 채워진 path: 사용자가 선택한 색상
        canvas.drawPath(cp.path, Paint()
          ..color = filledColor
          ..style = PaintingStyle.fill);
      } else {
        // 미채움 path: 흰색으로 내부 덮기
        canvas.drawPath(cp.path, whitePaint);
        if (cp.isInteractive && hintOpacity > 0.0) {
          canvas.drawPath(
            cp.path,
            Paint()
              ..color = cp.fillColor.withValues(alpha: hintOpacity)
              ..style = PaintingStyle.fill,
          );
        }
      }
    }

    // 진행 중인 채우기 애니메이션 (여러 개 동시 렌더)
    for (final anim in activeAnimations) {
      anim.painter.paint(
        canvas,
        size,
        anim.targetPath,
        anim.fillColor,
        anim.t,
        anim.tapOffset,
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
      old.strokeOpacity != strokeOpacity ||
      old.activeAnimations != activeAnimations;
}
