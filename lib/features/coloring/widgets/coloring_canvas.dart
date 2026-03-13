import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/features/coloring/animations/fill_animation_painter.dart';
import 'package:toktok_drawing/features/coloring/animations/fill_animation_selector.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_transform.dart';
import 'package:toktok_drawing/features/coloring/painters/coloring_painter.dart';
import 'package:toktok_drawing/features/coloring/providers/coloring_provider.dart';

class ColoringCanvas extends ConsumerStatefulWidget {
  final ui.FragmentProgram? pencilProgram;

  const ColoringCanvas({super.key, this.pencilProgram});

  @override
  ConsumerState<ColoringCanvas> createState() => _ColoringCanvasState();
}

class _ColoringCanvasState extends ConsumerState<ColoringCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  FillAnimationPainter? _activePainter;
  ui.Path? _animTargetPath;
  Color? _animFillColor;
  Offset? _animTapOffset;
  int? _animatingPathIndex;
  ColoringTransform? _transform;
  Size? _lastCanvasSize;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..addListener(_onAnimationTick)
      ..addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() => setState(() {});

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // 애니메이션 완료 → path를 filled로 전환
      if (_animatingPathIndex != null) {
        ref.read(coloringProvider.notifier).fillPath(_animatingPathIndex!);
      }
      ref.read(coloringProvider.notifier).setAnimating(false);
      setState(() {
        _activePainter = null;
        _animTargetPath = null;
        _animFillColor = null;
        _animTapOffset = null;
        _animatingPathIndex = null;
      });
    }
  }

  void _onTap(Offset canvasOffset) {
    final state = ref.read(coloringProvider);

    // 애니메이션 진행 중 탭 차단
    if (state.isAnimating) return;

    if (_transform == null) return;

    // SVG 좌표계로 역변환
    final svgOffset = _transform!.toSvgOffset(canvasOffset);

    // Hit detection: 소형/흰색/이미 채워진 path 제외, 역순(z-order 상위 우선)
    ColoringPath? hit;
    for (final cp in state.parsedPaths.reversed) {
      if (!cp.isInteractive) continue;
      if (state.filledPaths.contains(cp.index)) continue;
      if (!cp.bounds.contains(svgOffset)) continue;
      if (cp.path.contains(svgOffset)) {
        hit = cp;
        break;
      }
    }

    if (hit == null) return;

    // 효과 선택 및 애니메이션 시작
    final painter = FillAnimationSelector.select(
      bounds: hit.bounds,
      fillColor: hit.fillColor,
      tapOffset: svgOffset,
      pencilProgram: widget.pencilProgram,
    );

    _animController.duration = painter.duration;
    _animController.reset();

    ref.read(coloringProvider.notifier).setAnimating(true);

    setState(() {
      _activePainter = painter;
      _animTargetPath = hit!.path;
      _animFillColor = hit.fillColor;
      _animTapOffset = svgOffset;
      _animatingPathIndex = hit.index;
    });

    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coloringProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        // 캔버스 크기 변경 시 transform 갱신
        if (_lastCanvasSize != canvasSize) {
          _lastCanvasSize = canvasSize;
          _transform = ColoringTransform.forCanvas(canvasSize);
        }

        return GestureDetector(
          onTapDown: (d) => _onTap(d.localPosition),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: ColoringPainter(
                paths: state.parsedPaths,
                filledPaths: state.filledPaths,
                activeAnimation: _activePainter,
                animationTargetPath: _animTargetPath,
                animationFillColor: _animFillColor,
                animationTapOffset: _animTapOffset,
                animationT: _animController.value,
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
