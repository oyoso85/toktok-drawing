import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/widgets/brush_size_selector.dart';

class FreeDrawingState {
  final List<DrawingElement> elements;
  final List<DrawingElement> redoStack;
  final DrawingElement? currentElement;

  final Color selectedColor;
  final DrawingTool selectedTool;
  final double selectedSize;
  final Color backgroundColor;

  // 무지개 붓: 획 시작 시각 (포인트 색상 계산용)
  final DateTime? strokeStartTime;

  // 꽃씨 붓: 마지막 파티클 생성 위치 + 팔레트
  final Offset? lastSparklePoint;
  final List<Color> sparklePalette;

  const FreeDrawingState({
    required this.elements,
    required this.redoStack,
    this.currentElement,
    required this.selectedColor,
    required this.selectedTool,
    required this.selectedSize,
    required this.backgroundColor,
    this.strokeStartTime,
    this.lastSparklePoint,
    required this.sparklePalette,
  });

  factory FreeDrawingState.initial() => FreeDrawingState(
        elements: const [],
        redoStack: const [],
        selectedColor: AppColors.palette.first,
        selectedTool: DrawingTool.pen,
        selectedSize: BrushSizeSelector.sizes[1],
        backgroundColor: Colors.white,
        sparklePalette: const [],
      );

  bool get canUndo => elements.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  FreeDrawingState copyWith({
    List<DrawingElement>? elements,
    List<DrawingElement>? redoStack,
    DrawingElement? currentElement,
    bool clearCurrentElement = false,
    Color? selectedColor,
    DrawingTool? selectedTool,
    double? selectedSize,
    Color? backgroundColor,
    DateTime? strokeStartTime,
    bool clearStrokeStartTime = false,
    Offset? lastSparklePoint,
    bool clearLastSparklePoint = false,
    List<Color>? sparklePalette,
  }) {
    return FreeDrawingState(
      elements: elements ?? this.elements,
      redoStack: redoStack ?? this.redoStack,
      currentElement: clearCurrentElement
          ? null
          : (currentElement ?? this.currentElement),
      selectedColor: selectedColor ?? this.selectedColor,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedSize: selectedSize ?? this.selectedSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      strokeStartTime: clearStrokeStartTime
          ? null
          : (strokeStartTime ?? this.strokeStartTime),
      lastSparklePoint: clearLastSparklePoint
          ? null
          : (lastSparklePoint ?? this.lastSparklePoint),
      sparklePalette: sparklePalette ?? this.sparklePalette,
    );
  }
}
