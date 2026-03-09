import 'dart:convert';
import 'dart:ui';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_mode.dart';
import 'package:toktok_drawing/shared/models/rainbow_stroke.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';

class DrawingData {
  final String id;
  final DrawingMode mode;
  final List<DrawingElement> elements;
  final Color backgroundColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? templateId;

  DrawingData({
    required this.id,
    required this.mode,
    List<DrawingElement>? elements,
    this.backgroundColor = const Color(0xFFFFFFFF),
    DateTime? createdAt,
    DateTime? updatedAt,
    this.templateId,
  })  : elements = elements ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DrawingData copyWith({
    List<DrawingElement>? elements,
    Color? backgroundColor,
    DateTime? updatedAt,
  }) {
    return DrawingData(
      id: id,
      mode: mode,
      elements: elements ?? this.elements,
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
      'elements': elements.map((e) => e.toJson()).toList(),
      'backgroundColor': backgroundColor.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'templateId': templateId,
    };
    return jsonEncode(map);
  }

  factory DrawingData.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

    // 구 데이터 호환: 'strokes' 키 지원 (type 필드 없음 → Stroke로 처리)
    final rawElements = (map['elements'] ?? map['strokes']) as List? ?? [];

    return DrawingData(
      id: map['id'] as String,
      mode: DrawingMode.values[map['mode'] as int],
      elements: rawElements
          .map((e) => _elementFromJson(e as Map<String, dynamic>))
          .toList(),
      backgroundColor: Color(map['backgroundColor'] as int),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      templateId: map['templateId'] as String?,
    );
  }

  static DrawingElement _elementFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'stroke';
    switch (type) {
      case 'rainbow_stroke':
        return RainbowStroke.fromJson(json);
      case 'sparkle':
        return SparkleElement.fromJson(json);
      default:
        return Stroke.fromJson(json);
    }
  }
}
