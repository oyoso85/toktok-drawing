import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/features/coloring/models/svg_template.dart';
import 'package:toktok_drawing/features/coloring/providers/coloring_provider.dart';
import 'package:toktok_drawing/features/coloring/services/coloring_progress_service.dart';
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
  final List<SvgTemplate> allTemplates;
  final int templateIndex;

  const ColoringScreen({
    super.key,
    required this.svgAssetPath,
    this.allTemplates = const [],
    this.templateIndex = 0,
  });

  @override
  ConsumerState<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends ConsumerState<ColoringScreen> {
  ui.FragmentProgram? _pencilProgram;
  bool _loading = true;
  bool _showingCompletion = false;
  bool _showingPopup = false;
  bool _showEarlyNextButton = false;
  bool _showAutoCompleteButton = false;

  // ── 디버그: 단면 순서 자동 채우기 ──────────────────────────────────────────
  Timer? _debugTimer;
  int _debugCurrentIndex = -1; // 현재 채우는 interactivePaths 순번 (0-based)

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

  void _startDebugAutoFill() {
    final notifier = ref.read(coloringProvider.notifier);
    final paths = ref.read(coloringProvider).interactivePaths;

    // 초기화
    notifier.initPaths(widget.svgAssetPath);
    setState(() => _debugCurrentIndex = -1);
    _debugTimer?.cancel();

    int step = 0;
    _debugTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (step >= paths.length) {
        timer.cancel();
        setState(() => _debugCurrentIndex = -1);
        return;
      }
      final p = paths[step];
      notifier.fillPath(p.index, p.fillColor);
      setState(() => _debugCurrentIndex = step);
      step++;
    });
  }

  void _stopDebugAutoFill() {
    _debugTimer?.cancel();
    setState(() => _debugCurrentIndex = -1);
  }

  @override
  void dispose() {
    _debugTimer?.cancel();
    super.dispose();
  }

  void _onCompletionDone() {
    if (mounted) {
      setState(() {
        _showingCompletion = false;
        _showingPopup = true;
      });
      ref.read(coloringProvider.notifier).resetCompletion();
    }
  }

  void _goNext() {
    final nextIndex = widget.templateIndex + 1;
    if (nextIndex < widget.allTemplates.length) {
      final next = widget.allTemplates[nextIndex];
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ColoringScreen(
          svgAssetPath: next.assetPath,
          allTemplates: widget.allTemplates,
          templateIndex: nextIndex,
        ),
      ));
    } else {
      Navigator.of(context).pop();
    }
  }

  void _autoComplete() {
    ref.read(coloringProvider.notifier).fillAllRemaining();
    setState(() => _showAutoCompleteButton = false);
  }

  void _replay() {
    setState(() {
      _showingPopup = false;
      _showEarlyNextButton = false;
      _showAutoCompleteButton = false;
    });
    ref.read(coloringProvider.notifier).initPaths(widget.svgAssetPath);
  }

  @override
  Widget build(BuildContext context) {
    // 완성 이벤트 감지
    ref.listen(coloringProvider.select((s) => s.isCompleted), (_, isCompleted) {
      if (isCompleted && !_showingCompletion) {
        setState(() {
          _showingCompletion = true;
          _showEarlyNextButton = false;
          _showAutoCompleteButton = false;
        });
        // 완성 상태 저장
        final filledPaths = ref.read(coloringProvider).filledPaths;
        ColoringProgressService.instance
            .saveCompleted(widget.svgAssetPath, filledPaths);
      }
    });

    // 2번 색칠 후 다음 버튼 표시 / 90% 이상 채우면 자동완성 버튼 표시
    ref.listen(
      coloringProvider.select((s) => (filled: s.filledPaths.length, total: s.interactivePaths.length)),
      (_, val) {
        final filled = val.filled;
        final total = val.total;
        if (!_showEarlyNextButton && filled >= 2) {
          setState(() => _showEarlyNextButton = true);
        }
        if (total > 0 && !_showAutoCompleteButton && filled < total && filled >= (total * 0.9).ceil()) {
          setState(() => _showAutoCompleteButton = true);
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
            return GestureDetector(
              onLongPress: _loading
                  ? null
                  : () {
                      if (_debugTimer?.isActive == true) {
                        _stopDebugAutoFill();
                      } else {
                        _startDebugAutoFill();
                      }
                    },
              child: Text(
                total == 0 ? '색칠하기' : '색칠하기  $filled / $total',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
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
                // 2번 색칠 후 오른쪽 위에서 슬라이드로 나타나는 다음 버튼
                Positioned(
                  top: 16,
                  right: 0,
                  child: AnimatedSlide(
                    offset: _showEarlyNextButton ? Offset.zero : const Offset(1.5, 0),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    child: _EarlyNextButton(onTap: _goNext),
                  ),
                ),
                // 90% 이상 채우면 나타나는 자동완성 버튼 (다음 버튼 아래)
                Positioned(
                  top: 80,
                  right: 0,
                  child: AnimatedSlide(
                    offset: _showAutoCompleteButton ? Offset.zero : const Offset(1.5, 0),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    child: _AutoCompleteButton(onTap: _autoComplete),
                  ),
                ),
                if (_showingCompletion)
                  CompletionOverlay(onDone: _onCompletionDone),
                if (_showingPopup)
                  _CompletionPopup(
                    hasNext: widget.templateIndex + 1 < widget.allTemplates.length,
                    onNext: _goNext,
                    onReplay: _replay,
                  ),
                if (_debugCurrentIndex >= 0)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 80, // 팔레트 패널 너비 제외
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          '${_debugCurrentIndex + 1}번째 단면',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── 조기 다음 버튼 (2번 색칠 후 오른쪽 위 슬라이드) ─────────────────────────────
class _EarlyNextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EarlyNextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 20, right: 12, top: 12, bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            bottomLeft: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              offset: const Offset(-2, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('다음', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 자동완성 버튼 (90% 이상 채웠을 때) ──────────────────────────────────────────
class _AutoCompleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AutoCompleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 20, right: 12, top: 12, bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            bottomLeft: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
              offset: const Offset(-2, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('완성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            SizedBox(width: 6),
            Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 완성 팝업 ─────────────────────────────────────────────────────────────────

class _CompletionPopup extends StatelessWidget {
  final bool hasNext;
  final VoidCallback onNext;
  final VoidCallback onReplay;

  const _CompletionPopup({
    required this.hasNext,
    required this.onNext,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                const Text(
                  '완성!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '정말 잘했어요!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      hasNext ? '다음 그림 →' : '처음으로 →',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onReplay,
                  child: const Text(
                    '다시 그리기',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
