import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/features/drawing/placeholder_drawing_screen.dart';
import 'package:toktok_drawing/features/free_drawing/free_drawing_screen.dart';
import 'package:toktok_drawing/features/mode_selection/models/mode_info.dart';
import 'package:toktok_drawing/features/mode_selection/widgets/mode_card.dart';
import 'package:toktok_drawing/features/color_by_symbol/color_by_symbol_screen.dart';
import 'package:toktok_drawing/features/coloring/coloring_select_screen.dart';
import 'package:toktok_drawing/features/trace_drawing/trace_drawing_screen.dart';
import 'package:toktok_drawing/shared/models/drawing_mode.dart';

const _kPrimary = AppColors.primary;

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  void _go(BuildContext context, ModeInfo info) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => switch (info.mode) {
        DrawingMode.free => const FreeDrawingScreen(),
        DrawingMode.trace => const TraceDrawingScreen(),
        DrawingMode.colorBySymbol => const ColorBySymbolScreen(),
        DrawingMode.coloring => const ColoringSelectScreen(),
        _ => PlaceholderDrawingScreen(
            mode: info.mode,
            title: info.title,
            onAutoSave: () async {},
          ),
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BgCircles(),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: _Body(onTap: (info) => _go(context, info)),
                ),
                const _BottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 배경 장식 원 ─────────────────────────────────────────────────────────────

class _BgCircles extends StatelessWidget {
  const _BgCircles();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -80,
          child: _Circle(320, _kPrimary.withValues(alpha: 0.25)),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height / 2,
          right: -80,
          child: _Circle(240, _kPrimary.withValues(alpha: 0.15)),
        ),
        Positioned(
          bottom: -80,
          left: MediaQuery.of(context).size.width / 4,
          child: _Circle(380, _kPrimary.withValues(alpha: 0.20)),
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ── 상단 앱바 ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 450;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isCompact ? 8 : 16),
      child: Row(
        children: [
          _RoundButton(icon: Icons.home_rounded, onTap: () {}),
          const Expanded(child: _Title()),
          const _ScoreBadge(score: 1240),
          const SizedBox(width: 12),
          _RoundButton(
            icon: Icons.settings_rounded,
            iconColor: Colors.grey.shade500,
            borderColor: Colors.grey.shade200,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    this.iconColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? _kPrimary.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? _kPrimary,
          size: 26,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '톡톡 그림판',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _kPrimary,
            letterSpacing: 1.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TitleDot(size: 8, color: _kPrimary),
            const SizedBox(width: 3),
            _TitleDash(),
            const SizedBox(width: 3),
            _TitleDot(size: 8, color: _kPrimary),
          ],
        ),
      ],
    );
  }
}

class _TitleDot extends StatelessWidget {
  final double size;
  final Color color;
  const _TitleDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _TitleDash extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 8,
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3), width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: _kPrimary, size: 20),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 본문: 좌(마스코트) + 우(카드 2줄) ──────────────────────────────────────────

class _Body extends StatefulWidget {
  final void Function(ModeInfo) onTap;
  const _Body({required this.onTap});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _fadeAnim(int index) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(index * 0.15, (index * 0.15 + 0.6).clamp(0, 1),
            curve: Curves.easeOut),
      );

  Animation<Offset> _slideAnim(int index) => Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(index * 0.15, (index * 0.15 + 0.6).clamp(0, 1),
            curve: Curves.easeOut),
      ));

  @override
  Widget build(BuildContext context) {
    final modes = ModeInfo.registry;
    final hasThreeRows = modes.length > 4;
    final isCompact = MediaQuery.of(context).size.height < 450;
    final cardHeight = isCompact
        ? (hasThreeRows ? 88.0 : 110.0)
        : (hasThreeRows ? 120.0 : 160.0);
    final rowGap = isCompact ? 8.0 : (hasThreeRows ? 10.0 : 14.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 0, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좌: 마스코트 (화면의 약 30%)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.30,
            child: const _MascotColumn(),
          ),
          const SizedBox(width: 16),
          // 우: 카드 2~3줄 (가로 스크롤)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CardRow(
                  modes: modes.take(2).toList(),
                  onTap: widget.onTap,
                  fadeAnim: _fadeAnim(0),
                  slideAnim: _slideAnim(0),
                  cardHeight: cardHeight,
                ),
                SizedBox(height: rowGap),
                _CardRow(
                  modes: modes.skip(2).take(2).toList(),
                  onTap: widget.onTap,
                  fadeAnim: _fadeAnim(2),
                  slideAnim: _slideAnim(2),
                  cardHeight: cardHeight,
                ),
                if (hasThreeRows) ...[
                  SizedBox(height: rowGap),
                  _CardRow(
                    modes: modes.skip(4).toList(),
                    onTap: widget.onTap,
                    fadeAnim: _fadeAnim(4),
                    slideAnim: _slideAnim(4),
                    cardHeight: cardHeight,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 마스코트 컬럼 (좌측 고정 영역) ───────────────────────────────────────────

class _MascotColumn extends StatefulWidget {
  const _MascotColumn();

  @override
  State<_MascotColumn> createState() => _MascotColumnState();
}

class _MascotColumnState extends State<_MascotColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 마스코트 이미지 (pulsing) - Flexible로 남은 공간만큼만 차지
        Flexible(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Image.asset(
              'assets/images/mascot.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // LET'S DRAW! 버튼
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _kPrimary, width: 3),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.35),
                offset: const Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Text(
            "LET'S DRAW!",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _kPrimary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── 카드 행 (가로 스크롤) ─────────────────────────────────────────────────────

class _CardRow extends StatelessWidget {
  final List<ModeInfo> modes;
  final void Function(ModeInfo) onTap;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final double cardHeight;

  const _CardRow({
    required this.modes,
    required this.onTap,
    required this.fadeAnim,
    required this.slideAnim,
    this.cardHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ModeCard(
              modeInfo: modes[i],
              index: i,
              onTap: () => onTap(modes[i]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 하단 바 ──────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  void _snack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('준비 중이에요! 🚧'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: MediaQuery.of(context).size.height < 450 ? 8 : 14,
          ),
          child: Row(
            children: [
              _PillButton(
                icon: Icons.photo_library_rounded,
                label: '내 갤러리',
                onTap: () => _snack(context),
              ),
              const SizedBox(width: 12),
              _PillButton(
                icon: Icons.star_rounded,
                label: 'Daily Challenge',
                onTap: () => _snack(context),
              ),
              const Spacer(),
              Text(
                '열심히 그려봐요! ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade400,
                ),
              ),
              GestureDetector(
                onTap: () => _snack(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: _kPrimary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kPrimary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
