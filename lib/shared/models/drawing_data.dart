import 'dart:convert';
import 'dart:ui';
import 'package:toktok_drawing/shared/models/drawing_mode.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';

class DrawingData {
  final String id;
  final DrawingMode mode;
  final List<Stroke> strokes;
  final Color backgroundColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? templateId;

  DrawingData({
    required this.id,
    required this.mode,
    List<Stroke>? strokes,
    this.backgroundColor = const Color(0xFFFFFFFF),
    DateTime? createdAt,
    DateTime? updatedAt,
    this.templateId,
  })  : strokes = strokes ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DrawingData copyWith({
    List<Stroke>? strokes,
    Color? backgroundColor,
    DateTime? updatedAt,
  }) {
    return DrawingData(
      id: id,
      mode: mode,
      strokes: strokes ?? this.strokes,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      templateId: templateId,
    );
  }

  String toJsonString() {
    final map = {
      'id': id,
      'mode': mode.index,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'backgroundColor': backgroundColor.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'templateId': templateId,
    };
    return jsonEncode(map);
  }

  factory DrawingData.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return DrawingData(
      id: map['id'] as String,
      mode: DrawingMode.values[map['mode'] as int],
      strokes: (map['strokes'] as List)
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      backgroundColor: Color(map['backgroundColor'] as int),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      templateId: map['templateId'] as String?,
    );
  }
}
