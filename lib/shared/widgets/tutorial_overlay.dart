import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum TutorialGesture {
  drawStroke, // 자유 그리기: 도구→색→크기 설명 후 좌→우 드래그
  tracePath, // 선 따라 그리기: 설명 없이 바로 ghost hand
  tapToFill, // 색칠하기: 색깔 설명 후 탭 애니메이션
}

// ── 화면 내 강조 영역 (비율 기반) ───────────────────────────────────────────

class _AnnotationStep {
  final String emoji;
  final String label;
  // 강조 사각형 (0.0~1.0 비율)
  final double hLeft;
  final double hRight;
  final double hTop;
  final double hBottom;
  // 말풍선 중심 x (0.0~1.0)
  final double bubbleX;

  const _AnnotationStep({
    required this.emoji,
    required this.label,
    required this.hLeft,
    required this.hRight,
    required this.hTop,
    required this.hBottom,
    required this.bubbleX,
  });
}

// 가로 모드 기준:
//   DrawingToolbar 높이 ≈ 화면 하단 18%
//   [도구 0~18%] [색상 18~74%] [굵기 74~87%] [취소/재실행 87~100%]
List<_AnnotationStep> _stepsFor(TutorialGesture gesture) {
  switch (gesture) {
    case TutorialGesture.drawStroke:
      return const [
        _AnnotationStep(
          emoji: '✏️',
          label: '그리기 도구를 골라요',
          hLeft: 0.0,
          hRight: 0.19,
          hTop: 0.82,
          hBottom: 1.0,
          bubbleX: 0.15,
        ),
        _AnnotationStep(
          emoji: '🎨',
          label: '색깔을 골라요',
          hLeft: 0.19,
          hRight: 0.74,
          hTop: 0.82,
          hBottom: 1.0,
          bubbleX: 0.46,
        ),
        _AnnotationStep(
          emoji: '🖊️',
          label: '펜 굵기를 바꿔요',
          hLeft: 0.74,
          hRight: 0.89,
          hTop: 0.82,
          hBottom: 1.0,
          bubbleX: 0.80,
        ),
      ];
    case TutorialGesture.tapToFill:
      return const [
        _AnnotationStep(
          emoji: '🎨',
          label: '색깔을 골라요',
          hLeft: 0.88,
          hRight: 1.0,
          hTop: 0.0,
          hBottom: 1.0,
          bubbleX: 0.60,
        ),
      ];
    case TutorialGesture.tracePath:
      return const []; // 설명 없이 바로 따라그리기
  }
}

// ── 메인 위젯 ────────────────────────────────────────────────────────────────

enum _Phase { guide, tryIt }

class TutorialOverlay extends StatefulWidget {
  final TutorialGesture gesture;
  final VoidCallback onDismiss;
  final Duration autoDismissAfter;

  const TutorialOverlay({
    super.key,
    required this.gesture,
    required this.onDismiss,
    this.autoDismissAfter = const Duration(seconds: 5),
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late final List<_AnnotationStep> _steps;
  int _stepIndex = 0;
  _Phase _phase = _Phase.guide;

  // intro/outro 공통 페이드
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  // 말풍선 슬라이드 (guide 단계)
  late final AnimationController _bubbleCtrl;
  late final Animation<Offset> _bubbleSlide;

  // ghost hand (tryIt 단계)
  late final AnimationController _gestureCtrl;

  Timer? _dismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _steps = _stepsFor(widget.gesture);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bubbleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bubbleCtrl, curve: Curves.easeOut));

    _gestureCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeCtrl.forward().then((_) => _bubbleCtrl.forward());

    if (_steps.isEmpty) _enterTryIt();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _fadeCtrl.dispose();
    _bubbleCtrl.dispose();
    _gestureCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_phase == _Phase.guide) {
      if (_stepIndex < _steps.length - 1) {
        // 다음 설명 단계
        _bubbleCtrl.reset();
        setState(() => _stepIndex++);
        _bubbleCtrl.forward();
      } else {
        // 설명 끝 → 따라해보세요 단계
        _enterTryIt();
      }
    } else {
      _dismiss();
    }
  }

  void _enterTryIt() {
    _bubbleCtrl.stop();
    setState(() => _phase = _Phase.tryIt);
    _gestureCtrl.repeat();
    _dismissTimer = Timer(widget.autoDismissAfter, _dismiss);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _dismissTimer?.cancel();
    _fadeCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  // ── 손 위치 계산 ───────────────────────────────────────────────────────────

  Offset _handPosition(double t, Size size) {
    switch (widget.gesture) {
      case TutorialGesture.drawStroke:
        final progress = t < 0.1
            ? 0.0
            : t < 0.8
                ? (t - 0.1) / 0.7
                : 1.0;
        final u = Curves.easeInOut.transform(progress);
        return Offset(
          size.width * (0.2 + u * 0.6),
          size.height * (0.55 - u * 0.1),
        );
      case TutorialGesture.tracePath:
        final progress = t < 0.1
            ? 0.0
            : t < 0.85
                ? (t - 0.1) / 0.75
                : 1.0;
        final u = Curves.easeInOut.transform(progress);
        final p0 = Offset(size.width * 0.2, size.height * 0.7);
        final p1 = Offset(size.width * 0.5, size.height * 0.2);
        final p2 = Offset(size.width * 0.8, size.height * 0.65);
        return Offset(
          math.pow(1 - u, 2) * p0.dx +
              2 * (1 - u) * u * p1.dx +
              math.pow(u, 2) * p2.dx,
          math.pow(1 - u, 2) * p0.dy +
              2 * (1 - u) * u * p1.dy +
              math.pow(u, 2) * p2.dy,
        );
      case TutorialGesture.tapToFill:
        final cx = size.width * 0.45;
        if (t < 0.35) {
          final p = Curves.easeIn.transform(t / 0.35);
          return Offset(cx, size.height * (0.3 + p * 0.2));
        } else if (t < 0.6) {
          return Offset(cx, size.height * 0.5);
        } else if (t < 0.85) {
          final p = Curves.easeOut.transform((t - 0.6) / 0.25);
          return Offset(cx, size.height * (0.5 - p * 0.2));
        } else {
          return Offset(cx, size.height * 0.3);
        }
    }
  }

  double _handOpacity(double t) {
    if (t < 0.08) return t / 0.08;
    if (t > 0.88) return (1.0 - t) / 0.12;
    return 1.0;
  }

  double _handScale(double t) {
    if (widget.gesture != TutorialGesture.tapToFill) return 1.0;
    if (t >= 0.35 && t < 0.5) {
      return 1.0 + math.sin((t - 0.35) / 0.15 * math.pi) * 0.25;
    }
    return 1.0;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: FadeTransition(
        opacity: _fade,
        child: _phase == _Phase.guide ? _buildGuide() : _buildTryIt(),
      ),
    );
  }

  // ── Phase 1: UI 설명 ──────────────────────────────────────────────────────

  Widget _buildGuide() {
    if (_steps.isEmpty) return const SizedBox.shrink();
    final step = _steps[_stepIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        final hRect = Rect.fromLTRB(
          size.width * step.hLeft,
          size.height * step.hTop,
          size.width * step.hRight,
          size.height * step.hBottom,
        );

        return Stack(
          children: [
            // 스포트라이트 배경
            CustomPaint(
              size: size,
              painter: _SpotlightPainter(highlight: hRect),
            ),
            // 스텝 인디케이터 (좌상단)
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: List.generate(_steps.length, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _stepIndex ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _stepIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // 말풍선
            Positioned(
              left: 0,
              right: 0,
              // 강조 영역이 하단이면 말풍선은 위, 우측이면 왼쪽
              bottom: step.hTop > 0.5
                  ? size.height * (1.0 - step.hTop) + 20
                  : null,
              top: step.hLeft > 0.7
                  ? size.height * 0.3
                  : null,
              child: SlideTransition(
                position: _bubbleSlide,
                child: Align(
                  alignment: Alignment(
                    (step.bubbleX * 2 - 1).clamp(-0.9, 0.9),
                    0,
                  ),
                  child: _Callout(
                    emoji: step.emoji,
                    label: step.label,
                    isLast: _stepIndex == _steps.length - 1,
                  ),
                ),
              ),
            ),
            // 하단 힌트
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '화면을 탭하면 다음으로 넘어가요',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Phase 2: 따라해보세요 ─────────────────────────────────────────────────

  Widget _buildTryIt() {
    return Stack(
      children: [
        // 배경
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.38),
          ),
        ),
        // 상단 라벨
        Positioned(
          top: 36,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '이렇게 따라 해보세요! 🖐️',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF6B6B),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
        // 하단 탭 안내
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '화면을 탭하면 시작해요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // 애니메이션 손
        AnimatedBuilder(
          animation: _gestureCtrl,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final size =
                    Size(constraints.maxWidth, constraints.maxHeight);
                final t = _gestureCtrl.value;
                final pos = _handPosition(t, size);
                final opacity = _handOpacity(t).clamp(0.0, 1.0);
                final scale = _handScale(t);

                return Stack(
                  children: [
                    if (widget.gesture != TutorialGesture.tapToFill)
                      IgnorePointer(
                        child: CustomPaint(
                          size: size,
                          painter: _TrailPainter(
                            gesture: widget.gesture,
                            t: t,
                            size: size,
                            handPositionFn: _handPosition,
                          ),
                        ),
                      ),
                    if (widget.gesture == TutorialGesture.tapToFill)
                      IgnorePointer(
                        child: CustomPaint(
                          size: size,
                          painter: _RipplePainter(t: t, pos: pos),
                        ),
                      ),
                    Positioned(
                      left: pos.dx - 20,
                      top: pos.dy - 8,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: const Icon(
                            Icons.back_hand_rounded,
                            size: 52,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x88000000),
                                blurRadius: 8,
                                offset: Offset(2, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ── 말풍선 위젯 ───────────────────────────────────────────────────────────────

class _Callout extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isLast;

  const _Callout({
    required this.emoji,
    required this.label,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF333333),
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isLast ? '해보자!' : '다음 →',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 스포트라이트 페인터 ────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect highlight;

  const _SpotlightPainter({required this.highlight});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 어두운 배경
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // 강조 영역 구멍 (투명)
    final rRect = RRect.fromRectAndRadius(
      highlight.inflate(4),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rRect,
      Paint()..blendMode = BlendMode.clear,
    );

    // 강조 영역 테두리 glow
    canvas.drawRRect(
      rRect,
      Paint()
        ..blendMode = BlendMode.srcOver
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.highlight != highlight;
}

// ── 혜성 꼬리 페인터 ──────────────────────────────────────────────────────────

class _TrailPainter extends CustomPainter {
  final TutorialGesture gesture;
  final double t;
  final Size size;
  final Offset Function(double t, Size size) handPositionFn;

  _TrailPainter({
    required this.gesture,
    required this.t,
    required this.size,
    required this.handPositionFn,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (int i = 1; i <= 8; i++) {
      final pastT = (t - i * 0.04).clamp(0.0, 1.0);
      final pastPos = handPositionFn(pastT, size);
      final opacity = (1.0 - i / 8) * 0.35;
      final radius = (12.0 - i * 1.2).clamp(2.0, 12.0);
      canvas.drawCircle(
        pastPos + const Offset(12, 20),
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.t != t;
}

// ── 탭 ripple 페인터 ──────────────────────────────────────────────────────────

class _RipplePainter extends CustomPainter {
  final double t;
  final Offset pos;

  _RipplePainter({required this.t, required this.pos});

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0.3 || t > 0.75) return;
    final rippleT = ((t - 0.3) / 0.45).clamp(0.0, 1.0);
    final radius = rippleT * 60.0;
    final opacity = (1.0 - rippleT) * 0.5;
    canvas.drawCircle(
      pos + const Offset(12, 20),
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}
