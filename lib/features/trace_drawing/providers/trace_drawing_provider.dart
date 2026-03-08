import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';
import 'trace_drawing_state.dart';

/// 6.7 선 따라 그리기 Riverpod Provider.
/// 가이드 선은 상태에 포함되지 않음 — 가이드 선은 TraceTemplate에서 빌드.
class TraceDrawingNotifier extends Notifier<TraceDrawingState> {
  @override
  TraceDrawingState build() => TraceDrawingState.initial();

  // ── 스트로크 제스처 ─────────────────────────────────────
  void startStroke(Offset point) {
    final stroke = Stroke(
      points: [point],
      color: state.selectedColor,
      size: state.selectedSize,
      tool: state.selectedTool,
    );
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

  // ── 6.6 실행 취소 / 다시 실행 ────────────────────────────
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

  /// 6.6 전체 지우기: 사용자 스트로크만 제거, 가이드 선은 유지.
  void clearStrokes() {
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

  /// 새 템플릿 선택 시 이전 스트로크 초기화.
  void resetForTemplate() {
    state = TraceDrawingState.initial();
  }
}

final traceDrawingProvider =
    NotifierProvider<TraceDrawingNotifier, TraceDrawingState>(
  TraceDrawingNotifier.new,
);
