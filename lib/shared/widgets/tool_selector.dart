import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/tool_colors.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/widgets/animated_pressable.dart';

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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: DrawingTool.values.map((tool) {
        final isSelected = tool == selectedTool;
        final colorSet = ToolColors.of(tool);
        final isRainbow = tool == DrawingTool.rainbowBrush;

        return AnimatedPressable(
          onTap: () => onToolSelected(tool),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 52,
            height: 58,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isSelected && isRainbow
                  ? ToolColors.rainbowGradient
                  : null,
              color: isSelected && !isRainbow
                  ? colorSet.active
                  : !isSelected
                      ? colorSet.bg
                      : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorSet.glow,
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _toolIcons[tool],
                  size: 24,
                  color: isSelected ? Colors.white : colorSet.active,
                ),
                const SizedBox(height: 3),
                Text(
                  _toolLabels[tool]!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : colorSet.active,
                    fontWeight: FontWeight.bold,
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
