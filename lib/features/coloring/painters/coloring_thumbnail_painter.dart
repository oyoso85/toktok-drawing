import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';

/// 색칠하기 선택 화면의 썸네일용 CustomPainter.
/// [filledPaths]가 있으면 완성된 컬러로 렌더링, 없으면 흰색 + 검정 테두리(미완성).
/// non-interactive path(배경·장식)는 항상 SVG 원본 색상으로 표시.
class ColoringThumbnailPainter extends CustomPainter {
  final List<ColoringPath> paths;
  final Float64List? transformMatrix;

  /// 완성된 색칠 상태. null이면 미완성(흰색+테두리).
  final Map<int, Color>? filledPaths;

  const ColoringThumbnailPainter({
    required this.paths,
    this.transformMatrix,
    this.filledPaths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (transformMatrix != null) {
      canvas.save();
      canvas.transform(transformMatrix!);
    }

    final outerStrokePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final cp in paths) {
      // 흰색·검정만 원본 색으로 미리 채움. isTiny 유색은 일반 path와 동일하게 처리.
      if (cp.isWhite || cp.isBlack) {
        canvas.drawPath(
          cp.path,
          Paint()
            ..color = cp.fillColor
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      final savedColor = filledPaths?[cp.index];
      canvas.drawPath(cp.path, outerStrokePaint);
      if (savedColor != null) {
        // 완성된 도안: 저장된 색으로 채움
        canvas.drawPath(
          cp.path,
          Paint()
            ..color = savedColor
            ..style = PaintingStyle.fill,
        );
      } else {
        // 미완성: 흰색으로 내부 덮기
        canvas.drawPath(cp.path, whitePaint);
      }
    }

    if (transformMatrix != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ColoringThumbnailPainter old) =>
      old.paths != paths || old.filledPaths != filledPaths;
}
