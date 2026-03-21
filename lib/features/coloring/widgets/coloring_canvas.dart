import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/features/coloring/animations/active_fill_animation.dart';
import 'package:toktok_drawing/features/coloring/animations/fill_animation_selector.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_transform.dart';
import 'package:toktok_drawing/features/coloring/painters/coloring_painter.dart';
import 'package:toktok_drawing/features/coloring/providers/coloring_provider.dart';

/// 동시에 진행 중인 채우기 애니메이션 항목.
class _AnimEntry {
  final AnimationController controller;
  final ActiveFillAnimation Function() snapshot;
  final int pathIndex;
  final Color fillColor;

  _AnimEntry({
    required this.controller,
    required this.snapshot,
    required this.pathIndex,
    required this.fillColor,
  });
}

class ColoringCanvas extends ConsumerStatefulWidget {
  final ui.FragmentProgram? pencilProgram;

  const ColoringCanvas({super.key, this.pencilProgram});

  @override
  ConsumerState<ColoringCanvas> createState() => _ColoringCanvasState();
}

class _ColoringCanvasState extends ConsumerState<ColoringCanvas>
    with TickerProviderStateMixin {
  /// 미채움 단면 힌트: 0→10%→0 opacity, 1.5초 왕복 (3초 주기)
  late AnimationController _hintController;

  final List<_AnimEntry> _activeAnims = [];

  ColoringTransform? _transform;
  Size? _lastCanvasSize;
  Size? _lastSvgViewBox;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addListener(_onTick)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hintController.dispose();
    for (final entry in _activeAnims) {
      entry.controller.dispose();
    }
    _activeAnims.clear();
    super.dispose();
  }

  void _onTick() => setState(() {});

  void _onTap(Offset canvasOffset) {
    if (_transform == null) return;

    final state = ref.read(coloringProvider);

    // SVG 좌표계로 역변환
    final svgOffset = _transform!.toSvgOffset(canvasOffset);

    // 선택된 색이 없으면 탭 무시
    final selectedColor = state.selectedColor;
    if (selectedColor == null) return;

    // 현재 애니메이션 중인 path 인덱스 집합
    final animatingIndices = _activeAnims.map((e) => e.pathIndex).toSet();

    // Hit detection: 소형/흰색/이미 채워진/이미 애니메이션 중인 path 제외
    ColoringPath? hit;

    // 1단계: 정확한 탭
    for (final cp in state.parsedPaths.reversed) {
      if (!cp.isInteractive) continue;
      if (state.filledPaths.containsKey(cp.index)) continue;
      if (animatingIndices.contains(cp.index)) continue;
      if (!cp.bounds.contains(svgOffset)) continue;
      if (cp.path.contains(svgOffset)) {
        hit = cp;
        break;
      }
    }

    // 2단계: tolerance 범위 내 가장 작은 path (정확히 탭 못했을 때)
    if (hit == null) {
      const toleranceCanvasPx = 36.0;
      final tol = _transform!.toSvgDistance(toleranceCanvasPx);
      final toleranceCircle = ui.Path()
        ..addOval(Rect.fromCircle(center: svgOffset, radius: tol));

      ColoringPath? nearest;
      double nearestArea = double.infinity;

      for (final cp in state.parsedPaths) {
        if (!cp.isInteractive) continue;
        if (state.filledPaths.containsKey(cp.index)) continue;
        if (animatingIndices.contains(cp.index)) continue;
        if (!cp.bounds.inflate(tol).contains(svgOffset)) continue;

        final intersection = ui.Path.combine(
          ui.PathOperation.intersect, cp.path, toleranceCircle);
        if (intersection.getBounds().isEmpty) continue;

        final area = cp.bounds.width * cp.bounds.height;
        if (area < nearestArea) {
          nearestArea = area;
          nearest = cp;
        }
      }
      hit = nearest;
    }

    if (hit == null) return;

    // 선택한 색이 해당 단면의 원본 색과 다르면 채우지 않음
    if (selectedColor != hit.fillColor) return;

    // 효과 선택
    final painter = FillAnimationSelector.select(
      bounds: hit.bounds,
      fillColor: selectedColor,
      tapOffset: svgOffset,
      pencilProgram: widget.pencilProgram,
    );

    final controller = AnimationController(
      vsync: this,
      duration: painter.duration,
    );

    final capturedPath = hit.path;
    final capturedColor = selectedColor;
    final capturedTapOffset = svgOffset;
    final capturedIndex = hit.index;

    late _AnimEntry entry;

    entry = _AnimEntry(
      controller: controller,
      snapshot: () => ActiveFillAnimation(
        painter: painter,
        targetPath: capturedPath,
        fillColor: capturedColor,
        tapOffset: capturedTapOffset,
        t: controller.value,
      ),
      pathIndex: capturedIndex,
      fillColor: capturedColor,
    );

    controller.addListener(_onTick);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref
            .read(coloringProvider.notifier)
            .fillPath(entry.pathIndex, entry.fillColor);
        setState(() {
          _activeAnims.remove(entry);
        });
        controller.dispose();
      }
    });

    setState(() {
      _activeAnims.add(entry);
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coloringProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        // 캔버스 크기 또는 SVG viewBox 변경 시 transform 갱신
        if (_lastCanvasSize != canvasSize || _lastSvgViewBox != state.svgViewBox) {
          _lastCanvasSize = canvasSize;
          _lastSvgViewBox = state.svgViewBox;
          _transform = ColoringTransform.forCanvas(
            canvasSize,
            svgViewBox: state.svgViewBox,
          );
        }

        final activeAnimations = _activeAnims.map((e) => e.snapshot()).toList();

        return GestureDetector(
          onTapDown: (d) => _onTap(d.localPosition),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: ColoringPainter(
                paths: state.parsedPaths,
                filledPaths: state.filledPaths,
                hintOpacity: _hintController.value * 0.25,
                activeAnimations: activeAnimations,
                transformMatrix: _transform?.storage,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}
