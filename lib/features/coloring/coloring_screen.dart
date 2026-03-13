import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/features/coloring/providers/coloring_provider.dart';
import 'package:toktok_drawing/features/coloring/widgets/coloring_canvas.dart';
import 'package:toktok_drawing/features/coloring/widgets/completion_overlay.dart';

class ColoringScreen extends ConsumerStatefulWidget {
  const ColoringScreen({super.key});

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

    await ref.read(coloringProvider.notifier).initPaths();

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
        title: const Text(
          '색칠하기',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ColoringCanvas(pencilProgram: _pencilProgram),
                if (_showingCompletion)
                  CompletionOverlay(onDone: _onCompletionDone),
              ],
            ),
    );
  }
}
