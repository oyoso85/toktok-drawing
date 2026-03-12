import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/widgets/brush_size_selector.dart';

class TraceDrawingState {
  /// 사용자가 그린 요소 목록 (가이드 선 제외).
  final List<DrawingElement> elements;
  final List<DrawingElement> redoStack;
  final DrawingElement? currentElement;

  final Color selectedColor;
  final DrawingTool selectedTool;
  final double selectedSize;

  // 무지개 붓: 스트로크 시작 시각 (시간 기반 색상 계산)
  final DateTime? strokeStartTime;
  // 꽃씨 붓: 직전 파티클 위치 (거리 임계값 체크)
  final Offset? lastSparklePoint;
  final int sparkleColorIndex;
  final List<Color> sparklePalette;

  const TraceDrawingState({
    required this.elements,
    required this.redoStack,
    this.currentElement,
    required this.selectedColor,
    required this.selectedTool,
    required this.selectedSize,
    this.strokeStartTime,
    this.lastSparklePoint,
    this.sparkleColorIndex = 0,
    this.sparklePalette = const [],
  });

  factory TraceDrawingState.initial() => TraceDrawingState(
        elements: const [],
        redoStack: const [],
        selectedColor: AppColors.palette.first,
        selectedTool: DrawingTool.pen,
        selectedSize: BrushSizeSelector.sizes[1],
      );

  bool get canUndo => elements.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  TraceDrawingState copyWith({
    List<DrawingElement>? elements,
    List<DrawingElement>? redoStack,
    DrawingElement? currentElement,
    bool clearCurrentElement = false,
    Color? selectedColor,
    DrawingTool? selectedTool,
    double? selectedSize,
    DateTime? strokeStartTime,
    bool clearStrokeStartTime = false,
    Offset? lastSparklePoint,
    bool clearLastSparklePoint = false,
    int? sparkleColorIndex,
    List<Color>? sparklePalette,
  }) {
    return TraceDrawingState(
      elements: elements ?? this.elements,
      redoStack: redoStack ?? this.redoStack,
      currentElement: clearCurrentElement ? null : (currentElement ?? this.currentElement),
      selectedColor: selectedColor ?? this.selectedColor,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedSize: selectedSize ?? this.selectedSize,
      strokeStartTime: clearStrokeStartTime ? null : (strokeStartTime ?? this.strokeStartTime),
      lastSparklePoint: clearLastSparklePoint ? null : (lastSparklePoint ?? this.lastSparklePoint),
      sparkleColorIndex: sparkleColorIndex ?? this.sparkleColorIndex,
      sparklePalette: sparklePalette ?? this.sparklePalette,
    );
  }
}
