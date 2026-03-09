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
    DrawingTool.rainbowBrush: Icons.auto_awesome,
    DrawingTool.sparkleBrush: Icons.star,
  };

  static const _toolLabels = {
    DrawingTool.pen: '펜',
    DrawingTool.brush: '붓',
    DrawingTool.pencil: '색연필',
    DrawingTool.eraser: '지우개',
    DrawingTool.rainbowBrush: '무지개',
    DrawingTool.sparkleBrush: '꽃씨',
  };

  static bool _isMagic(DrawingTool tool) =>
      tool == DrawingTool.rainbowBrush || tool == DrawingTool.sparkleBrush;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: DrawingTool.values.map((tool) {
        final isSelected = tool == selectedTool;
        final isMagic = _isMagic(tool);

        final selectedBg = isMagic ? Colors.purple.shade100 : Colors.blue.shade100;
        final selectedBorder = isMagic ? Colors.purple : Colors.blue;
        final selectedIconColor = isMagic ? Colors.purple : Colors.blue;

        return GestureDetector(
          onTap: () => onToolSelected(tool),
          child: Container(
            width: 48,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? selectedBorder : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _toolIcons[tool],
                  size: 20,
                  color: isSelected ? selectedIconColor : Colors.grey.shade700,
                ),
                const SizedBox(height: 2),
                Text(
                  _toolLabels[tool]!,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? selectedIconColor : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
