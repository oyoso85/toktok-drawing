import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/widgets/animated_pressable.dart';

class BrushSizeSelector extends StatelessWidget {
  final double selectedSize;
  final ValueChanged<double> onSizeSelected;

  static const List<double> sizes = [16.0, 28.0, 44.0, 64.0];

  // 크기별 고유 컬러 (작→큰: 파랑→주황→핑크→보라)
  static const List<Color> _dotColors = [
    Color(0xFF4FC3F7), // 파랑
    Color(0xFFFFB74D), // 주황
    Color(0xFFF48FB1), // 핑크
    Color(0xFFCE93D8), // 보라
  ];

  const BrushSizeSelector({
    super.key,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(sizes.length, (index) {
        final size = sizes[index];
        final isSelected = size == selectedSize;
        final dotColor = _dotColors[index];
        final dotSize = size.clamp(10.0, 32.0);

        return AnimatedPressable(
          onTap: () => onSizeSelected(size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? dotColor.withValues(alpha: 0.18)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: dotColor, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
