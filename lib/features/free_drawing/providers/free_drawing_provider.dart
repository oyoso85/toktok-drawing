import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';
import 'free_drawing_state.dart';

class FreeDrawingNotifier extends Notifier<FreeDrawingState> {
  @override
  FreeDrawingState build() => FreeDrawingState.initial();

  // ── 스트로크 제스처 ─────────────────────────────────────
  void startStroke(Offset point) {
    final stroke = Stroke(
      points: [point],
      color: state.selectedColor,
      size: state.selectedSize,
      tool: state.selectedTool,
    );
    // 새 스트로크 시작 시 redo 스택 초기화
    state = state.copyWith(currentStroke: stroke, redoStack: []);
  }

  void addPoint(Offset point) {
    if (state.currentStroke == null) return;
    final updated = state.currentStroke!.copyWith(
      points: [...state.currentStroke!.points, point],
    );
    state = state.copyWith(currentStroke: updated);
  }

  void endStroke() {
    if (state.currentStroke == null) return;
    state = state.copyWith(
      strokes: [...state.strokes, state.currentStroke!],
      clearCurrentStroke: true,
    );
  }

  // ── 실행 취소 / 다시 실행 ────────────────────────────────
  void undo() {
    if (!state.canUndo) return;
    final last = state.strokes.last;
    state = state.copyWith(
      strokes: state.strokes.sublist(0, state.strokes.length - 1),
      redoStack: [...state.redoStack, last],
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final last = state.redoStack.last;
    state = state.copyWith(
      strokes: [...state.strokes, last],
      redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
    );
  }

  // ── 전체 지우기 (5.7) ───────────────────────────────────
  void clearAll() {
    state = state.copyWith(
      strokes: [],
      redoStack: [],
      clearCurrentStroke: true,
    );
  }

  // ── 도구 설정 ──────────────────────────────────────────
  void changeColor(Color color) => state = state.copyWith(selectedColor: color);
  void changeTool(DrawingTool tool) =>
      state = state.copyWith(selectedTool: tool);
  void changeSize(double size) => state = state.copyWith(selectedSize: size);

  // ── 배경색 변경 (5.6) ──────────────────────────────────
  void changeBackgroundColor(Color color) =>
      state = state.copyWith(backgroundColor: color);
}

final freeDrawingProvider =
    NotifierProvider<FreeDrawingNotifier, FreeDrawingState>(
  FreeDrawingNotifier.new,
);
