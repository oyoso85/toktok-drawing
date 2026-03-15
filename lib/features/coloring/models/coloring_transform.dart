import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

/// SVG viewBox를 캔버스 크기에 맞게 uniform scale + center 정렬하는 변환 행렬을 계산한다.
class ColoringTransform {
  final Matrix4 matrix;
  final Matrix4 _inverse;

  ColoringTransform._(this.matrix) : _inverse = Matrix4.copy(matrix)..invert();

  static const double padding = 24.0;

  factory ColoringTransform.forCanvas(Size canvasSize, {Size svgViewBox = const Size(630, 648)}) {
    final svgWidth = svgViewBox.width;
    final svgHeight = svgViewBox.height;
    final available = Size(
      canvasSize.width - padding * 2,
      canvasSize.height - padding * 2,
    );
    final scale = min(
      available.width / svgWidth,
      available.height / svgHeight,
    );
    final dx = (canvasSize.width - svgWidth * scale) / 2;
    final dy = (canvasSize.height - svgHeight * scale) / 2;

    final m = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);

    return ColoringTransform._(m);
  }

  /// canvas.transform() 에 전달할 Float64List.
  Float64List get storage => Float64List.fromList(matrix.storage.toList());

  /// 캔버스 좌표 -> SVG 좌표계 역변환 (hit detection용).
  Offset toSvgOffset(Offset canvasOffset) {
    final v = _inverse.transform3(
      Vector3(canvasOffset.dx, canvasOffset.dy, 0),
    );
    return Offset(v.x, v.y);
  }
}
