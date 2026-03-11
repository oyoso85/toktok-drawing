import 'dart:ui';
import 'package:flutter/material.dart' show HSLColor;
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';

class RainbowStroke implements DrawingElement {
  @override
  String get type => 'rainbow_stroke';

  final List<Offset> points;
  final List<Color> colors;
  final double size;
  final double blurSigma;
  final DrawingTool tool;

  const RainbowStroke({
    required this.points,
    required this.colors,
    required this.size,
    required this.blurSigma,
    this.tool = DrawingTool.pen,
  });

  RainbowStroke copyWith({
    List<Offset>? points,
    List<Color>? colors,
    double? size,
    double? blurSigma,
    DrawingTool? tool,
  }) {
    return RainbowStroke(
      points: points ?? this.points,
      colors: colors ?? this.colors,
      size: size ?? this.size,
      blurSigma: blurSigma ?? this.blurSigma,
      tool: tool ?? this.tool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'colors': colors.map((c) => c.toARGB32()).toList(),
      'size': size,
      'blurSigma': blurSigma,
      'tool': tool.index,
    };
  }

  factory RainbowStroke.fromJson(Map<String, dynamic> json) {
    return RainbowStroke(
      points: (json['points'] as List)
          .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList(),
      colors: (json['colors'] as List).map((c) => Color(c as int)).toList(),
      size: (json['size'] as num).toDouble(),
      blurSigma: (json['blurSigma'] as num).toDouble(),
      tool: json['tool'] != null
          ? DrawingTool.values[json['tool'] as int]
          : DrawingTool.pen,
    );
  }
}

/// 경과 시간(ms)으로 무지개 색상 계산. 10초(10000ms)에 전체 색상환 순환.
Color rainbowColorAt(int elapsedMs) {
  final hue = (elapsedMs % 10000) / 10000.0 * 360.0;
  return HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor();
}
