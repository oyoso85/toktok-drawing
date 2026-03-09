import 'dart:ui';
import 'package:toktok_drawing/shared/models/drawing_element.dart';

enum SparkleShape { star, heart, circle }

class SparkleObject {
  final Offset position;
  final SparkleShape shape;
  final Color color;
  final double finalSize;
  final double rotation;

  const SparkleObject({
    required this.position,
    required this.shape,
    required this.color,
    required this.finalSize,
    required this.rotation,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'shape': shape.index,
      'color': color.toARGB32(),
      'finalSize': finalSize,
      'rotation': rotation,
    };
  }

  factory SparkleObject.fromJson(Map<String, dynamic> json) {
    return SparkleObject(
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      shape: SparkleShape.values[json['shape'] as int],
      color: Color(json['color'] as int),
      finalSize: (json['finalSize'] as num).toDouble(),
      rotation: (json['rotation'] as num).toDouble(),
    );
  }
}

class SparkleElement implements DrawingElement {
  @override
  String get type => 'sparkle';

  final List<Color> palette;
  final List<SparkleObject> objects;

  const SparkleElement({
    required this.palette,
    required this.objects,
  });

  SparkleElement copyWith({
    List<Color>? palette,
    List<SparkleObject>? objects,
  }) {
    return SparkleElement(
      palette: palette ?? this.palette,
      objects: objects ?? this.objects,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'palette': palette.map((c) => c.toARGB32()).toList(),
      'objects': objects.map((o) => o.toJson()).toList(),
    };
  }

  factory SparkleElement.fromJson(Map<String, dynamic> json) {
    return SparkleElement(
      palette: (json['palette'] as List).map((c) => Color(c as int)).toList(),
      objects: (json['objects'] as List)
          .map((o) => SparkleObject.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}
