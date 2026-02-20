import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/free_drawing_provider.dart';
import 'widgets/drawing_canvas.dart';
import 'package:toktok_drawing/shared/widgets/drawing_toolbar.dart';

class FreeDrawingScreen extends ConsumerWidget {
  const FreeDrawingScreen({super.key});

  // 5.7 전체 지우기 확인 다이얼로그
  void _confirmClearAll(BuildContext context, FreeDrawingNotifier notifier) {
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
              Navigator.of(ctx).pop();
            },
            child: const Text('지우기'),
          ),
        ],
      ),
    );
  }

  // 5.6 배경색 선택 바텀시트
  void _showBgColorPicker(
    BuildContext context,
    FreeDrawingNotifier notifier,
    Color current,
  ) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(freeDrawingProvider);
    final notifier = ref.read(freeDrawingProvider.notifier);

    return PopScope(
      // 4.5 자동 저장 연동 (태스크 9에서 StorageService.save() 연결)
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
            // 5.6 배경색 버튼
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
                  _showBgColorPicker(context, notifier, state.backgroundColor),
            ),
            // 5.7 전체 지우기 버튼
            IconButton(
              tooltip: '전체 지우기',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmClearAll(context, notifier),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: DrawingCanvas(
                strokes: state.strokes,
                currentStroke: state.currentStroke,
                backgroundColor: state.backgroundColor,
                onPanStart: notifier.startStroke,
                onPanUpdate: notifier.addPoint,
                onPanEnd: notifier.endStroke,
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

// 5.6 배경색 선택 시트
class _BgColorSheet extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onSelected;

  static const _bgColors = [
    Colors.white,
    Color(0xFFFFF9E6), // 크림
    Color(0xFFE8F5E9), // 연초록
    Color(0xFFE3F2FD), // 연파랑
    Color(0xFFFCE4EC), // 연분홍
    Color(0xFFFFF8E1), // 연노랑
    Color(0xFF37474F), // 다크 그레이
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
