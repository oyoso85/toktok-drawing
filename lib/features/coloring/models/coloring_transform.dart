import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

/// character.svg viewBox(630x648)를 캔버스 크기에 맞게
/// uniform scale + center 정렬하는 변환 행렬을 계산한다.
class ColoringTransform {
  static const double svgWidth = 630.0;
  static const double svgHeight = 648.0;

  final Matrix4 matrix;
  final Matrix4 _inverse;

  ColoringTransform._(this.matrix) : _inverse = Matrix4.copy(matrix)..invert();

  factory ColoringTransform.forCanvas(Size canvasSize) {
    final scale = min(
      canvasSize.width / svgWidth,
      canvasSize.height / svgHeight,
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
