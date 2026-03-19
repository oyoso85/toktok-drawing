import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/core/utils/palette_utils.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_hitzone.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/rainbow_stroke.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/models/stroke.dart';
import 'trace_drawing_state.dart';

const _sparkleDistanceThreshold = 20.0;
const _sparkleMinSize = 16.0;
const _sparkleMaxSize = 36.0;
const _completionThreshold = 0.9;

/// 선 따라 그리기 Riverpod Provider.
/// 가이드 선은 상태에 포함되지 않음 — 가이드 선은 TraceTemplate에서 빌드.
class TraceDrawingNotifier extends Notifier<TraceDrawingState> {
  final _rng = Random();

  @override
  TraceDrawingState build() => TraceDrawingState.initial();

  // ── 스트로크 제스처 ─────────────────────────────────────
  void startStroke(Offset point) {
    if (state.isCompleted) return;

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
        state = state.copyWith(currentElement: stroke, strokeStartTime: now);

      case DrawingTool.sparkleBrush:
        final freshPalette = generateSparklePalette(state.selectedColor);
        state = state.copyWith(sparklePalette: freshPalette);
        final element = SparkleElement(
          palette: freshPalette,
          objects: [_newSparkleObject(point)],
        );
        state = state.copyWith(currentElement: element, lastSparklePoint: point);

      default:
        if (state.selectedColor == AppColors.kRainbow) {
          final now = DateTime.now();
          final stroke = RainbowStroke(
            points: [point],
            colors: [rainbowColorAt(0)],
            size: state.selectedSize,
            blurSigma: 0.0,
            tool: state.selectedTool,
          );
          state = state.copyWith(currentElement: stroke, strokeStartTime: now);
        } else {
          final stroke = Stroke(
            points: [point],
            color: state.selectedColor,
            size: state.selectedSize,
            tool: state.selectedTool,
          );
          state = state.copyWith(currentElement: stroke);
        }
    }
    _updateCoverage(point);
  }

  void addPoint(Offset point) {
    if (state.isCompleted) return;

    final current = state.currentElement;
    if (current == null) return;

    switch (state.selectedTool) {
      case DrawingTool.rainbowBrush:
        final stroke = current as RainbowStroke;
        if (stroke.points.isNotEmpty && (point - stroke.points.last).distance < 4.0) break;
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
          final isRainbow = state.selectedColor == AppColors.kRainbow;
          final nextIndex = isRainbow ? state.sparkleColorIndex + 1 : state.sparkleColorIndex;
          state = state.copyWith(
            currentElement: element.copyWith(objects: [...element.objects, newObj]),
            lastSparklePoint: point,
            sparkleColorIndex: nextIndex,
          );
        }

      default:
        if (current is RainbowStroke) {
          if (current.points.isNotEmpty && (point - current.points.last).distance < 4.0) break;
          final elapsedMs = state.strokeStartTime != null
              ? DateTime.now().difference(state.strokeStartTime!).inMilliseconds
              : 0;
          state = state.copyWith(
            currentElement: current.copyWith(
              points: [...current.points, point],
              colors: [...current.colors, rainbowColorAt(elapsedMs)],
            ),
          );
        } else {
          final stroke = current as Stroke;
          state = state.copyWith(
            currentElement: stroke.copyWith(points: [...stroke.points, point]),
          );
        }
    }
    _updateCoverage(point);
  }

  void endStroke() {
    if (state.isCompleted) return;
    final current = state.currentElement;
    if (current == null) return;
    state = state.copyWith(
      elements: [...state.elements, current],
      clearCurrentElement: true,
      clearStrokeStartTime: true,
      clearLastSparklePoint: true,
    );
    _checkCompletion();
  }

  // ── 실행 취소 / 다시 실행 ────────────────────────────
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

  /// 전체 지우기: 사용자 스트로크 + 커버리지 초기화.
  void clearStrokes() {
    state.hitZone?.reset();
    state = state.copyWith(
      elements: [],
      redoStack: [],
      clearCurrentElement: true,
    );
  }

  // ── 도구 설정 ──────────────────────────────────────────
  void changeColor(Color color) {
    final palette = state.selectedTool == DrawingTool.sparkleBrush
        ? generateSparklePalette(color)
        : state.sparklePalette;
    state = state.copyWith(selectedColor: color, sparklePalette: palette);
  }

  void changeTool(DrawingTool tool) {
    final palette = tool == DrawingTool.sparkleBrush
        ? generateSparklePalette(state.selectedColor)
        : state.sparklePalette;
    state = state.copyWith(selectedTool: tool, sparklePalette: palette);
  }

  void changeSize(double size) => state = state.copyWith(selectedSize: size);

  /// 새 도안 + 캔버스 크기로 히트존 생성 및 상태 초기화.
  void resetForTemplate(TraceTemplate template, Size canvasSize) {
    final path = template.pathBuilder(canvasSize);
    const hitRadius = 24.0; // 도구 굵기와 무관하게 고정
    final hitZone = HitZone.fromPath(path, hitRadius);
    state = TraceDrawingState.initial().copyWith(
      hitZone: hitZone,
      selectedColor: state.selectedColor,
      selectedSize: state.selectedSize,
      selectedTool: state.selectedTool,
    );
  }

  // ── 커버리지 업데이트 ──────────────────────────────────
  void _updateCoverage(Offset point) {
    final hz = state.hitZone;
    if (hz == null || state.isCompleted) return;
    final changed = hz.coverNear(point);
    if (changed.isNotEmpty) {
      state = state.copyWith(coverageVersion: state.coverageVersion + 1);
    }
  }

  void _checkCompletion() {
    final hz = state.hitZone;
    if (hz == null || state.isCompleted) return;
    if (hz.coverage >= _completionThreshold) {
      state = state.copyWith(isCompleted: true);
    }
  }

  // ── 내부 헬퍼 ────────────────────────────────────────────
  SparkleObject _newSparkleObject(Offset position) {
    final Color color;
    if (state.selectedColor == AppColors.kRainbow) {
      final hueIdx = (state.sparkleColorIndex ~/ 3) % rainbowColors.length;
      final subPalette = generateSparklePalette(rainbowColors[hueIdx]);
      color = subPalette[_rng.nextInt(subPalette.length)];
    } else {
      final palette = state.sparklePalette;
      color = palette.isEmpty ? const Color(0xFFFFD700) : palette[_rng.nextInt(palette.length)];
    }
    final shape = SparkleShape.values[_rng.nextInt(SparkleShape.values.length)];
    final size = _sparkleMinSize + _rng.nextDouble() * (_sparkleMaxSize - _sparkleMinSize);
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

final traceDrawingProvider =
    NotifierProvider<TraceDrawingNotifier, TraceDrawingState>(
  TraceDrawingNotifier.new,
);
