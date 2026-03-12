import 'package:flutter/material.dart';

class BrushSizeSelector extends StatelessWidget {
  final double selectedSize;
  final ValueChanged<double> onSizeSelected;

  static const List<double> sizes = [16.0, 28.0, 44.0, 64.0];
  static const List<String> labels = ['S', 'M', 'L', 'XL'];

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
        return GestureDetector(
          onTap: () => onSizeSelected(size),
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Container(
                width: size.clamp(10.0, 32.0),
                height: size.clamp(10.0, 32.0),
                decoration: const BoxDecoration(
                  color: Colors.black,
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
