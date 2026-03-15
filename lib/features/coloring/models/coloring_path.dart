import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// SVG의 단일 <path> 요소를 파싱한 결과.
class ColoringPath {
  final int index;
  final ui.Path path;
  final Color fillColor;
  final Rect bounds;

  /// bounding box 면적이 400px² 미만인 소형 장식 path.
  /// 처음부터 원본 색으로 표시되며 탭 대상에서 제외된다.
  final bool isTiny;

  /// fill 색상이 흰색 계열인 path. 처음부터 흰색으로 채워져 표시되며 탭 대상에서 제외.
  final bool isWhite;

  /// fill 색상이 검정 계열인 path. 처음부터 검정으로 채워져 표시되며 탭 대상에서 제외.
  final bool isBlack;

  const ColoringPath({
    required this.index,
    required this.path,
    required this.fillColor,
    required this.bounds,
    required this.isTiny,
    required this.isWhite,
    this.isBlack = false,
  });

  /// 사용자가 탭하여 채색할 수 있는 인터랙티브 단면인지 여부.
  bool get isInteractive => !isTiny && !isWhite && !isBlack;
}
