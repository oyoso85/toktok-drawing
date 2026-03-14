import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/features/coloring/providers/coloring_provider.dart';
import 'package:toktok_drawing/features/coloring/widgets/coloring_canvas.dart';
import 'package:toktok_drawing/features/coloring/widgets/completion_overlay.dart';

// ── 컬러 팔레트 패널 ───────────────────────────────────────────────────────────

class _ColorPalettePanel extends ConsumerWidget {
  const _ColorPalettePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coloringProvider);
    final colors = state.paletteColors;
    final selected = state.selectedColor;

    return Container(
      width: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final color in colors)
            _ColorButton(
              color: color,
              isSelected: selected == color,
              onTap: () =>
                  ref.read(coloringProvider.notifier).selectColor(color),
            ),
        ],
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 6),
        width: isSelected ? 44 : 36,
        height: isSelected ? 44 : 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 3)
              : Border.all(color: Colors.black12, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

class ColoringScreen extends ConsumerStatefulWidget {
  final String svgAssetPath;

  const ColoringScreen({super.key, required this.svgAssetPath});

  @override
  ConsumerState<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends ConsumerState<ColoringScreen> {
  ui.FragmentProgram? _pencilProgram;
  bool _loading = true;
  bool _showingCompletion = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // pencil 셰이더 로드 시도 (실패해도 계속 진행)
    try {
      _pencilProgram =
          await ui.FragmentProgram.fromAsset('assets/shaders/pencil.frag');
    } catch (_) {
      // fallback: pencil 셰이더 없이 일반 Paint 사용
    }

    await ref.read(coloringProvider.notifier).initPaths(widget.svgAssetPath);

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _onCompletionDone() {
    if (mounted) {
      setState(() => _showingCompletion = false);
      ref.read(coloringProvider.notifier).resetCompletion();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 완성 이벤트 감지
    ref.listen(coloringProvider.select((s) => s.isCompleted), (_, isCompleted) {
      if (isCompleted && !_showingCompletion) {
        setState(() => _showingCompletion = true);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(coloringProvider);
            final total = state.interactivePaths.length;
            final filled = state.filledPaths.length;
            return Text(
              total == 0 ? '색칠하기' : '색칠하기  $filled / $total',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ColoringCanvas(pencilProgram: _pencilProgram),
                    ),
                    const _ColorPalettePanel(),
                  ],
                ),
                if (_showingCompletion)
                  CompletionOverlay(onDone: _onCompletionDone),
              ],
            ),
    );
  }
}
