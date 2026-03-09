import 'dart:ui';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';

class Stroke implements DrawingElement {
  @override
  String get type => 'stroke';

  final List<Offset> points;
  final Color color;
  final double size;
  final DrawingTool tool;

  const Stroke({
    required this.points,
    required this.color,
    required this.size,
    required this.tool,
  });

  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    DrawingTool? tool,
  }) {
    return Stroke(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      tool: tool ?? this.tool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.toARGB32(),
      'size': size,
      'tool': tool.index,
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List)
          .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList(),
      color: Color(json['color'] as int),
      size: (json['size'] as num).toDouble(),
      tool: DrawingTool.values[json['tool'] as int],
    );
  }
}
