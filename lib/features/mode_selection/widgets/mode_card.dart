import 'package:flutter/material.dart';
import '../models/mode_info.dart';

/// 모드 선택 카드 위젯.
/// 일정 시간 유휴 상태에서 흔들리기+바운스 애니메이션을 반복 실행.
/// [index]를 통해 카드마다 애니메이션 시작 딜레이를 다르게 줘 자연스러움 연출.
class ModeCard extends StatefulWidget {
  final ModeInfo modeInfo;
  final VoidCallback onTap;
  final int index;

  const ModeCard({
    super.key,
    required this.modeInfo,
    required this.onTap,
    required this.index,
  });

  @override
  State<ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<ModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnim;
  late final Animation<double> _scaleAnim;

  bool _isRunning = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 0 → +max → -max → 0 : 좌우 흔들리기
    _rotationAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.08)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.08, end: -0.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.08, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]).animate(_controller);

    // 1.0 → 1.1 → 1.0 : 통통 바운스
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 1,
      ),
    ]).animate(_controller);

    // 카드 인덱스마다 다른 딜레이로 시작 → 동시에 같이 움직이지 않음
    final initialDelay = Duration(milliseconds: 1500 + widget.index * 600);
    Future.delayed(initialDelay, _startIdleLoop);
  }

  Future<void> _startIdleLoop() async {
    while (mounted) {
      if (!_isRunning) {
        _isRunning = true;
        await _controller.forward();
        _controller.reset();
        _isRunning = false;
      }
      // 한 번 흔든 후 2.5초 쉬었다가 반복
      await Future.delayed(const Duration(milliseconds: 2500));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: Transform.rotate(
          angle: _rotationAnim.value,
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Card(
          color: widget.modeInfo.cardColor,
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.modeInfo.icon, size: 64),
                const SizedBox(height: 12),
                Text(
                  widget.modeInfo.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.modeInfo.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
