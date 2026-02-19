import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';

class ToolSelector extends StatelessWidget {
  final DrawingTool selectedTool;
  final ValueChanged<DrawingTool> onToolSelected;

  const ToolSelector({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
  });

  static const _toolIcons = {
    DrawingTool.pen: Icons.edit,
    DrawingTool.brush: Icons.brush,
    DrawingTool.pencil: Icons.create,
    DrawingTool.eraser: Icons.auto_fix_high,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: DrawingTool.values.map((tool) {
        final isSelected = tool == selectedTool;
        return GestureDetector(
          onTap: () => onToolSelected(tool),
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _toolIcons[tool],
                  size: 22,
                  color: isSelected ? Colors.blue : Colors.grey.shade700,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
