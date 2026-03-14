import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';

/// 색칠하기 선택 화면의 썸네일용 CustomPainter.
/// 모든 interactive path를 흰색 fill + 검정 stroke으로 렌더링.
/// non-interactive path(배경·장식)는 SVG 원본 색상으로 표시.
class ColoringThumbnailPainter extends CustomPainter {
  final List<ColoringPath> paths;
  final Float64List? transformMatrix;

  const ColoringThumbnailPainter({
    required this.paths,
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
        canvas.drawPath(
          cp.path,
          Paint()
            ..color = cp.fillColor
            ..style = PaintingStyle.fill,
        );
        continue;
      }
      canvas.drawPath(cp.path, whitePaint);
      canvas.drawPath(cp.path, strokePaint);
    }

    if (transformMatrix != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ColoringThumbnailPainter old) => old.paths != paths;
}
