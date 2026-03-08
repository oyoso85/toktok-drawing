import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import '../models/mode_info.dart';

const _kPrimary = AppColors.primary;

/// 레퍼런스 디자인 기반 모드 카드.
/// - 흰 배경, 두꺼운 흰 테두리, 골드 하단 그림자 (card-shadow)
/// - 상단: imagePath 있으면 이미지, 없으면 색상 배경 + 아이콘
/// - 하단: 흰 배경 타이틀 영역
/// - 유휴 시 흔들기 + 살짝 들리는 애니메이션
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
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;
  late final Animation<double> _scale;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _rotate = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 0.07)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 0.07, end: -0.07)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: -0.07, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
    ]).animate(_ctrl);

    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.07)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 1.07, end: 1.0)
              .chain(CurveTween(curve: Curves.bounceOut)),
          weight: 1),
    ]).animate(_ctrl);

    Future.delayed(
      Duration(milliseconds: 1800 + widget.index * 700),
      _idleLoop,
    );
  }

  Future<void> _idleLoop() async {
    while (mounted) {
      if (!_busy) {
        _busy = true;
        await _ctrl.forward();
        _ctrl.reset();
        _busy = false;
      }
      await Future.delayed(const Duration(milliseconds: 2800));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColors = AppColors.modeCardBg;
    final idx = widget.modeInfo.gradientIndex.clamp(0, bgColors.length - 1);
    final bgColor = bgColors[idx];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => Transform.scale(
        scale: _scale.value,
        child: Transform.rotate(angle: _rotate.value, child: child),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              // 레퍼런스 card-shadow: 골드 하단 그림자
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.25),
                offset: const Offset(0, 8),
                blurRadius: 0,
                spreadRadius: 0,
              ),
              // 일반 드롭 섀도우
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // 상단 이미지 / 색상 영역
              Expanded(
                flex: 3,
                child: widget.modeInfo.imagePath != null
                    ? Image.asset(
                        widget.modeInfo.imagePath!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        width: double.infinity,
                        color: bgColor,
                        child: Center(
                          child: Icon(
                            widget.modeInfo.icon,
                            size: 56,
                            color: _kPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
              ),
              // 하단 타이틀 영역
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Text(
                  widget.modeInfo.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
