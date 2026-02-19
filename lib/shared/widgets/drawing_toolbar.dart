import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/widgets/brush_size_selector.dart';
import 'package:toktok_drawing/shared/widgets/color_palette.dart';
import 'package:toktok_drawing/shared/widgets/tool_selector.dart';

class DrawingToolbar extends StatelessWidget {
  final Color selectedColor;
  final double selectedSize;
  final DrawingTool selectedTool;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<DrawingTool> onToolChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const DrawingToolbar({
    super.key,
    required this.selectedColor,
    required this.selectedSize,
    required this.selectedTool,
    required this.canUndo,
    required this.canRedo,
    required this.onColorChanged,
    required this.onSizeChanged,
    required this.onToolChanged,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 색상 팔레트
            ColorPalette(
              selectedColor: selectedColor,
              onColorSelected: onColorChanged,
            ),
            const SizedBox(height: 8),
            // 도구 + 크기 + 실행 취소/다시 실행
            Row(
              children: [
                ToolSelector(
                  selectedTool: selectedTool,
                  onToolSelected: onToolChanged,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BrushSizeSelector(
                    selectedSize: selectedSize,
                    onSizeSelected: onSizeChanged,
                  ),
                ),
                const SizedBox(width: 8),
                _UndoRedoButtons(
                  canUndo: canUndo,
                  canRedo: canRedo,
                  onUndo: onUndo,
                  onRedo: onRedo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UndoRedoButtons extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const _UndoRedoButtons({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: canUndo ? onUndo : null,
          icon: const Icon(Icons.undo, size: 28),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
          ),
        ),
        IconButton(
          onPressed: canRedo ? onRedo : null,
          icon: const Icon(Icons.redo, size: 28),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
          ),
        ),
      ],
    );
  }
}
