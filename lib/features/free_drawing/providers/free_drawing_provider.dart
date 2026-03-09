import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/core/utils/palette_utils.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/rainbow_stroke.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';
import 'free_drawing_state.dart';

const _sparkleDistanceThreshold = 20.0;
const _sparkleMinSize = 16.0;
const _sparkleMaxSize = 36.0;

class FreeDrawingNotifier extends Notifier<FreeDrawingState> {
  final _rng = Random();

  @override
  FreeDrawingState build() => FreeDrawingState.initial();

  // ── 스트로크 제스처 ─────────────────────────────────────
  void startStroke(Offset point) {
    state = state.copyWith(redoStack: []);

    switch (state.selectedTool) {
      case DrawingTool.rainbowBrush:
        final now = DateTime.now();
        final color = rainbowColorAt(0);
        final stroke = RainbowStroke(
          points: [point],
          colors: [color],
          size: state.selectedSize,
          blurSigma: state.selectedSize * 0.3,
        );
        state = state.copyWith(
          currentElement: stroke,
          strokeStartTime: now,
        );

      case DrawingTool.sparkleBrush:
        final freshPalette = generateSparklePalette(state.selectedColor);
        state = state.copyWith(sparklePalette: freshPalette);
        final element = SparkleElement(
          palette: freshPalette,
          objects: [_newSparkleObject(point)],
        );
        state = state.copyWith(
          currentElement: element,
          lastSparklePoint: point,
        );

      default:
        final stroke = Stroke(
          points: [point],
          color: state.selectedColor,
          size: state.selectedSize,
          tool: state.selectedTool,
        );
        state = state.copyWith(currentElement: stroke);
    }
  }

  void addPoint(Offset point) {
    final current = state.currentElement;
    if (current == null) return;

    switch (state.selectedTool) {
      case DrawingTool.rainbowBrush:
        final stroke = current as RainbowStroke;
        final elapsedMs = state.strokeStartTime != null
            ? DateTime.now().difference(state.strokeStartTime!).inMilliseconds
            : 0;
        final color = rainbowColorAt(elapsedMs);
        state = state.copyWith(
          currentElement: stroke.copyWith(
            points: [...stroke.points, point],
            colors: [...stroke.colors, color],
          ),
        );

      case DrawingTool.sparkleBrush:
        final element = current as SparkleElement;
        final last = state.lastSparklePoint;
        if (last == null || (point - last).distance >= _sparkleDistanceThreshold) {
          final newObj = _newSparkleObject(point);
          state = state.copyWith(
            currentElement: element.copyWith(
              objects: [...element.objects, newObj],
            ),
            lastSparklePoint: point,
          );
        }

      default:
        final stroke = current as Stroke;
        state = state.copyWith(
          currentElement: stroke.copyWith(
            points: [...stroke.points, point],
          ),
        );
    }
  }

  void endStroke() {
    final current = state.currentElement;
    if (current == null) return;
    state = state.copyWith(
      elements: [...state.elements, current],
      clearCurrentElement: true,
      clearStrokeStartTime: true,
      clearLastSparklePoint: true,
    );
  }

  // ── 실행 취소 / 다시 실행 ────────────────────────────────
  void undo() {
    if (!state.canUndo) return;
    final last = state.elements.last;
    state = state.copyWith(
      elements: state.elements.sublist(0, state.elements.length - 1),
      redoStack: [...state.redoStack, last],
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final last = state.redoStack.last;
    state = state.copyWith(
      elements: [...state.elements, last],
      redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
    );
  }

  // ── 전체 지우기 ──────────────────────────────────────────
  void clearAll() {
    state = state.copyWith(
      elements: [],
      redoStack: [],
      clearCurrentElement: true,
    );
  }

  // ── 도구 설정 ──────────────────────────────────────────
  void changeColor(Color color) {
    // 꽃씨 붓 사용 중이면 새 색상 기반으로 팔레트 즉시 갱신
    final palette = state.selectedTool == DrawingTool.sparkleBrush
        ? generateSparklePalette(color)
        : state.sparklePalette;
    state = state.copyWith(selectedColor: color, sparklePalette: palette);
  }

  void changeTool(DrawingTool tool) {
    // 꽃씨 붓 선택 시 현재 선택 색상 기반 팔레트 생성
    final palette = tool == DrawingTool.sparkleBrush
        ? generateSparklePalette(state.selectedColor)
        : state.sparklePalette;
    state = state.copyWith(selectedTool: tool, sparklePalette: palette);
  }

  void changeSize(double size) => state = state.copyWith(selectedSize: size);

  // ── 배경색 변경 ──────────────────────────────────────────
  void changeBackgroundColor(Color color) =>
      state = state.copyWith(backgroundColor: color);

  // ── 내부 헬퍼 ────────────────────────────────────────────
  SparkleObject _newSparkleObject(Offset position) {
    final palette = state.sparklePalette;
    final color = palette.isEmpty
        ? const Color(0xFFFFD700)
        : palette[_rng.nextInt(palette.length)];
    final shape = SparkleShape.values[_rng.nextInt(SparkleShape.values.length)];
    final size = _sparkleMinSize +
        _rng.nextDouble() * (_sparkleMaxSize - _sparkleMinSize);
    final rotation = _rng.nextDouble() * 2 * 3.141592653589793;
    return SparkleObject(
      position: position,
      shape: shape,
      color: color,
      finalSize: size,
      rotation: rotation,
    );
  }
}

final freeDrawingProvider =
    NotifierProvider<FreeDrawingNotifier, FreeDrawingState>(
  FreeDrawingNotifier.new,
);
