import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/core/utils/palette_utils.dart';
import 'package:toktok_drawing/shared/widgets/animated_pressable.dart';

class ColorPalette extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final List<Color> colors;
  final bool disabled;

  const ColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colors = AppColors.palette,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.35 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final color = colors[index];
              final isSelected = color == selectedColor;
              final isRainbow = color == AppColors.kRainbow;
              final glowColor = isRainbow
                  ? Colors.purple.withValues(alpha: 0.55)
                  : color.withValues(alpha: 0.55);

              return AnimatedPressable(
                onTap: () => onColorSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  width: isSelected ? 50 : 42,
                  height: isSelected ? 50 : 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isRainbow
                        ? SweepGradient(colors: rainbowColors)
                        : null,
                    color: isRainbow ? null : color,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: glowColor,
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
