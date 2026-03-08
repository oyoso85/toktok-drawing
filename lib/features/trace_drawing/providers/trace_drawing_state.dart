import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';
import 'package:toktok_drawing/shared/widgets/brush_size_selector.dart';

class TraceDrawingState {
  /// 사용자가 그린 스트로크 목록 (가이드 선 제외).
  final List<Stroke> strokes;
  final List<Stroke> redoStack;
  final Stroke? currentStroke;

  final Color selectedColor;
  final DrawingTool selectedTool;
  final double selectedSize;

  const TraceDrawingState({
    required this.strokes,
    required this.redoStack,
    this.currentStroke,
    required this.selectedColor,
    required this.selectedTool,
    required this.selectedSize,
  });

  factory TraceDrawingState.initial() => TraceDrawingState(
        strokes: const [],
        redoStack: const [],
        selectedColor: AppColors.palette.first,
        selectedTool: DrawingTool.pen,
        selectedSize: BrushSizeSelector.sizes[1],
      );

  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  TraceDrawingState copyWith({
    List<Stroke>? strokes,
    List<Stroke>? redoStack,
    Stroke? currentStroke,
    bool clearCurrentStroke = false,
    Color? selectedColor,
    DrawingTool? selectedTool,
    double? selectedSize,
  }) {
    return TraceDrawingState(
      strokes: strokes ?? this.strokes,
      redoStack: redoStack ?? this.redoStack,
      currentStroke:
          clearCurrentStroke ? null : (currentStroke ?? this.currentStroke),
      selectedColor: selectedColor ?? this.selectedColor,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedSize: selectedSize ?? this.selectedSize,
    );
  }
}
