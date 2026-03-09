import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_shape_painter.dart';

/// 파티클 하나가 씨앗처럼 0 → finalSize로 피어나는 애니메이션 위젯.
/// 애니메이션 완료 시 [onComplete] 호출.
class SparkleObjectWidget extends StatefulWidget {
  final SparkleObject object;
  final VoidCallback onComplete;

  const SparkleObjectWidget({
    super.key,
    required this.object,
    required this.onComplete,
  });

  @override
  State<SparkleObjectWidget> createState() => _SparkleObjectWidgetState();
}

class _SparkleObjectWidgetState extends State<SparkleObjectWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obj = widget.object;
    final size = obj.finalSize;

    return Positioned(
      left: obj.position.dx - size / 2,
      top: obj.position.dy - size / 2,
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, __) => Transform.scale(
          scale: _scaleAnim.value,
          child: CustomPaint(
            painter: SparkleObjectPainter(obj),
          ),
        ),
      ),
    );
  }
}
