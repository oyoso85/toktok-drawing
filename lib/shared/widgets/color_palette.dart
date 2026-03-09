import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/core/utils/palette_utils.dart';

class ColorPalette extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final List<Color> colors;

  const ColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colors = AppColors.palette,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = color == selectedColor;
          final isRainbow = color == AppColors.kRainbow;

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isRainbow
                    ? SweepGradient(colors: rainbowColors)
                    : null,
                color: isRainbow ? null : color,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: isRainbow
                            ? Colors.purple.withValues(alpha: 0.5)
                            : color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      )]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
