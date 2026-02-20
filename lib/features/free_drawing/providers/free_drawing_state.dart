import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';
import 'package:toktok_drawing/shared/widgets/brush_size_selector.dart';

class FreeDrawingState {
  final List<Stroke> strokes;
  final List<Stroke> redoStack;
  final Stroke? currentStroke;
  final Color selectedColor;
  final DrawingTool selectedTool;
  final double selectedSize;
  final Color backgroundColor;

  const FreeDrawingState({
    required this.strokes,
    required this.redoStack,
    this.currentStroke,
    required this.selectedColor,
    required this.selectedTool,
    required this.selectedSize,
    required this.backgroundColor,
  });

  factory FreeDrawingState.initial() => FreeDrawingState(
        strokes: const [],
        redoStack: const [],
        selectedColor: AppColors.palette.first,
        selectedTool: DrawingTool.pen,
        selectedSize: BrushSizeSelector.sizes[1],
        backgroundColor: Colors.white,
      );

  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  FreeDrawingState copyWith({
    List<Stroke>? strokes,
    List<Stroke>? redoStack,
    Stroke? currentStroke,
    bool clearCurrentStroke = false,
    Color? selectedColor,
    DrawingTool? selectedTool,
    double? selectedSize,
    Color? backgroundColor,
  }) {
    return FreeDrawingState(
      strokes: strokes ?? this.strokes,
      redoStack: redoStack ?? this.redoStack,
      currentStroke:
          clearCurrentStroke ? null : (currentStroke ?? this.currentStroke),
      selectedColor: selectedColor ?? this.selectedColor,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedSize: selectedSize ?? this.selectedSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
