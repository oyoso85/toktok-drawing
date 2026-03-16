import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/widgets/brush_size_selector.dart';
import 'package:toktok_drawing/shared/widgets/color_palette.dart';
import 'package:toktok_drawing/shared/widgets/tool_selector.dart';

/// 그리기 툴바.
///
/// 가로 모드 전용 단일 행 레이아웃:
///   [도구 선택(가로 스크롤)] | [색상 팔레트(Expanded)] | [굵기] | [취소/재실행]
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 상단 rainbow 구분선
        Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF5252),
                Color(0xFFFF9800),
                Color(0xFFFFEB3B),
                Color(0xFF4CAF50),
                Color(0xFF2196F3),
                Color(0xFF9C27B0),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF9F0), Color(0xFFF0F9FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 도구 선택 — 좁은 화면에서도 스크롤로 모두 접근 가능
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ToolSelector(
                    selectedTool: selectedTool,
                    onToolSelected: onToolChanged,
                  ),
                ),
                const SizedBox(width: 8),
                // 색상 팔레트 — 남은 가로 공간 전부 사용
                Expanded(
                  child: ColorPalette(
                    selectedColor: selectedColor,
                    onColorSelected: onColorChanged,
                    disabled: selectedTool == DrawingTool.rainbowBrush ||
                        selectedTool == DrawingTool.eraser,
                  ),
                ),
                const SizedBox(width: 8),
                // 굵기 선택
                BrushSizeSelector(
                  selectedSize: selectedSize,
                  onSizeSelected: onSizeChanged,
                ),
                // 실행 취소 / 다시 실행
                _UndoRedoButtons(
                  canUndo: canUndo,
                  canRedo: canRedo,
                  onUndo: onUndo,
                  onRedo: onRedo,
                ),
              ],
            ),
          ),
        ),
      ],
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
