import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_shape_painter.dart';

/// 색칠 완성 시 전체 화면에 2.5초간 재생되는 Sparkle 축하 오버레이.
class CompletionOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const CompletionOverlay({super.key, required this.onDone});

  @override
  State<CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<CompletionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Confetti> _confetti;

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFF922B),
    Color(0xFFCC5DE8),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();

    final rng = math.Random();

    // 위→아래 (기존 방향, 2배 크기)
    final topDown = List.generate(120, (_) => _Confetti(
      x: rng.nextDouble(),
      y: -rng.nextDouble() * 0.3,
      vy: 0.25 + rng.nextDouble() * 0.55,
      vx: (rng.nextDouble() - 0.5) * 0.15,
      color: _colors[rng.nextInt(_colors.length)],
      size: 20 + rng.nextDouble() * 36,
      shape: SparkleShape.values[rng.nextInt(SparkleShape.values.length)],
      rotation: rng.nextDouble() * math.pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 4,
      delay: rng.nextDouble() * 0.4,
      upward: false,
    ));

    // 아래→위 (2배 크기)
    final bottomUp = List.generate(120, (_) => _Confetti(
      x: rng.nextDouble(),
      y: 1.0 + rng.nextDouble() * 0.3,
      vy: 0.25 + rng.nextDouble() * 0.55,
      vx: (rng.nextDouble() - 0.5) * 0.15,
      color: _colors[rng.nextInt(_colors.length)],
      size: 20 + rng.nextDouble() * 36,
      shape: SparkleShape.values[rng.nextInt(SparkleShape.values.length)],
      rotation: rng.nextDouble() * math.pi * 2,
      rotSpeed: (rng.nextDouble() - 0.5) * 4,
      delay: rng.nextDouble() * 0.4,
      upward: true,
    ));

    _confetti = [...topDown, ...bottomUp];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    final size = MediaQuery.of(context).size;

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(
            confetti: _confetti,
            t: t,
            canvasSize: size,
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double t;
  final Size canvasSize;

  const _ConfettiPainter({
    required this.confetti,
    required this.t,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final localT = ((t - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final opacity = localT < 0.8 ? 1.0 : (1 - (localT - 0.8) / 0.2);
      final x = (c.x + c.vx * localT) * size.width;
      final double y;
      if (c.upward) {
        y = (c.y - c.vy * localT) * size.height;
      } else {
        y = (c.y + c.vy * localT) * size.height;
      }
      final rotation = c.rotation + c.rotSpeed * localT;

      final obj = SparkleObject(
        position: Offset(x, y),
        shape: c.shape,
        color: c.color.withValues(alpha: opacity),
        finalSize: c.size,
        rotation: rotation,
      );
      drawSparkleObject(canvas, obj);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

class _Confetti {
  final double x, y, vy, vx;
  final Color color;
  final double size;
  final SparkleShape shape;
  final double rotation, rotSpeed, delay;
  final bool upward;

  const _Confetti({
    required this.x,
    required this.y,
    required this.vy,
    required this.vx,
    required this.color,
    required this.size,
    required this.shape,
    required this.rotation,
    required this.rotSpeed,
    required this.delay,
    required this.upward,
  });
}
