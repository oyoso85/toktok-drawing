import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_object_widget.dart';
import 'providers/free_drawing_provider.dart';
import 'providers/free_drawing_state.dart';
import 'widgets/drawing_canvas.dart';
import 'package:toktok_drawing/shared/widgets/drawing_toolbar.dart';

class FreeDrawingScreen extends ConsumerStatefulWidget {
  const FreeDrawingScreen({super.key});

  @override
  ConsumerState<FreeDrawingScreen> createState() => _FreeDrawingScreenState();
}

class _FreeDrawingScreenState extends ConsumerState<FreeDrawingScreen> {
  // 현재 피어나는 애니메이션 중인 파티클 목록
  final List<SparkleObject> _animatingObjects = [];

  // 색연필 Fragment Shader (비동기 로드)
  ui.FragmentShader? _pencilShader;

  @override
  void initState() {
    super.initState();
    _loadPencilShader();
  }

  Future<void> _loadPencilShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/pencil.frag',
      );
      if (mounted) {
        setState(() => _pencilShader = program.fragmentShader());
        debugPrint('pencil shader loaded OK');
      }
    } catch (e) {
      // shader 로드 실패 시 fallback(그레인 파티클)으로 자동 전환
      debugPrint('pencil shader load FAILED: $e');
    }
  }

  void _confirmClearAll(FreeDrawingNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 지우기'),
        content: const Text('그림을 모두 지울까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clearAll();
              setState(() => _animatingObjects.clear());
              Navigator.of(ctx).pop();
            },
            child: const Text('지우기'),
          ),
        ],
      ),
    );
  }

  void _showBgColorPicker(FreeDrawingNotifier notifier, Color current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _BgColorSheet(
        current: current,
        onSelected: (color) {
          notifier.changeBackgroundColor(color);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 꽃씨 붓 새 파티클 감지 → 애니메이션 큐에 추가
    ref.listen<FreeDrawingState>(freeDrawingProvider, (prev, next) {
      final prevCurrent = prev?.currentElement;
      final nextCurrent = next.currentElement;
      if (nextCurrent is SparkleElement) {
        final prevCount =
            prevCurrent is SparkleElement ? prevCurrent.objects.length : 0;
        final newObjects = nextCurrent.objects.skip(prevCount).toList();
        if (newObjects.isNotEmpty) {
          setState(() => _animatingObjects.addAll(newObjects));
        }
      }
    });

    final state = ref.watch(freeDrawingProvider);
    final notifier = ref.read(freeDrawingProvider.notifier);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          // TODO(task-9): await storageService.save(state)
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('자유 그리기'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: '배경색',
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: state.backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              onPressed: () =>
                  _showBgColorPicker(notifier, state.backgroundColor),
            ),
            IconButton(
              tooltip: '전체 지우기',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmClearAll(notifier),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  DrawingCanvas(
                    elements: state.elements,
                    currentElement: state.currentElement,
                    backgroundColor: state.backgroundColor,
                    onPanStart: notifier.startStroke,
                    onPanUpdate: notifier.addPoint,
                    onPanEnd: notifier.endStroke,
                    pencilShader: _pencilShader,
                  ),
                  // 꽃씨 붓 피어나는 애니메이션 오버레이
                  ..._animatingObjects.map((obj) => SparkleObjectWidget(
                        key: ValueKey(identityHashCode(obj)),
                        object: obj,
                        onComplete: () {
                          if (mounted) {
                            setState(() => _animatingObjects.remove(obj));
                          }
                        },
                      )),
                ],
              ),
            ),
            DrawingToolbar(
              selectedColor: state.selectedColor,
              selectedSize: state.selectedSize,
              selectedTool: state.selectedTool,
              canUndo: state.canUndo,
              canRedo: state.canRedo,
              onColorChanged: notifier.changeColor,
              onSizeChanged: notifier.changeSize,
              onToolChanged: notifier.changeTool,
              onUndo: notifier.undo,
              onRedo: notifier.redo,
            ),
          ],
        ),
      ),
    );
  }
}

class _BgColorSheet extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onSelected;

  static const _bgColors = [
    Colors.white,
    Color(0xFFFFF9E6),
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFCE4EC),
    Color(0xFFFFF8E1),
    Color(0xFF37474F),
  ];

  const _BgColorSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '배경 색상',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: _bgColors.map((color) {
                final isSelected = color.toARGB32() == current.toARGB32();
                return GestureDetector(
                  onTap: () => onSelected(color),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color == const Color(0xFF37474F)
                                ? Colors.white
                                : Colors.blue,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
