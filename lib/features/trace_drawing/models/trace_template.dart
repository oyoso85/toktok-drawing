import 'package:flutter/material.dart';

/// 선 따라 그리기 가이드 선 템플릿.
/// [pathBuilder]는 캔버스 Size를 받아 실제 그릴 Path를 반환.
/// [completionRect]는 캔버스 Size를 받아 완성 일러스트(color SVG)를 정확히 겹쳐 표시할 Rect를 반환.
/// 두 함수는 동일한 viewBox 기준으로 계산되어 완전히 일치한다.
class TraceTemplate {
  final String id;
  final String name;
  final Color thumbnailColor;
  final String svgAsset;

  /// 캔버스 Size를 받아 스케일된 Path를 반환.
  final Path Function(Size) pathBuilder;

  /// 캔버스 Size를 받아 color SVG를 겹쳐 표시할 Rect를 반환.
  final Rect Function(Size) completionRect;

  const TraceTemplate({
    required this.id,
    required this.name,
    required this.thumbnailColor,
    required this.svgAsset,
    required this.pathBuilder,
    required this.completionRect,
  });
}
