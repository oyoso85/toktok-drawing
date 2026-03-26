import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

const _kBackgrounds = [
  'assets/main/bg-farm.svg',
  'assets/main/bg-city.svg',
  'assets/main/bg-field.svg',
];

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  late final String _bg;

  @override
  void initState() {
    super.initState();
    _bg = _kBackgrounds[Random().nextInt(_kBackgrounds.length)];
  }

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(_bg, fit: BoxFit.cover),
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

// ── 상단 앱바 ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 450;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: isCompact ? 8 : 10),
      child: Row(
        children: [
          // 좌측 그룹 (homeBtn + scoreBadge)
          Expanded(
            child: Row(
              children: [
                _RoundButton(icon: Icons.home_rounded, onTap: () {}),
                const SizedBox(width: 12),
                const _ScoreBadge(score: 1240),
              ],
            ),
          ),
          // 중앙 타이틀
          const _Title(),
          // 우측 그룹 (settingsBtn)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RoundButton(
                  icon: Icons.settings_rounded,
                  iconColor: Colors.grey.shade500,
                  borderColor: Colors.grey.shade200,
                  onTap: () {},
                ),
              ],
            ),
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

// ── 본문: 좌(마스코트) + 우(카드 열 가로 스크롤) ────────────────────────────

const _kCardSize = 165.0;
const _kCardGap = 24.0;
const _kLockedCount = 3;

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

  @override
  Widget build(BuildContext context) {
    final modes = ModeInfo.registry;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 0, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좌: 마스코트
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.30,
            child: const _MascotColumn(),
          ),
          const SizedBox(width: 16),
          // 우: 열 기반 가로 스크롤 카드
          Expanded(
            child: Center(
              child: SizedBox(
                height: _kCardSize * 2 + _kCardGap + 32,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // col1: mode[0] (상) + mode[2] (하)
                      _ModeCardColumn(
                        top: modes[0],
                        bottom: modes[2],
                        onTap: widget.onTap,
                        colIndex: 0,
                        ctrl: _ctrl,
                      ),
                      const SizedBox(width: _kCardGap),
                      // col2: mode[1] (상) + mode[3] (하)
                      _ModeCardColumn(
                        top: modes[1],
                        bottom: modes[3],
                        onTap: widget.onTap,
                        colIndex: 1,
                        ctrl: _ctrl,
                      ),
                      const SizedBox(width: _kCardGap),
                      // col3: mode[4] (상) + locked (하)
                      _MixedCardColumn(
                        top: modes[4],
                        onTap: widget.onTap,
                        colIndex: 2,
                        ctrl: _ctrl,
                      ),
                      // 오픈 예정 열 2개
                      ...List.generate(_kLockedCount - 1, (i) => Row(
                        children: [
                          const SizedBox(width: _kCardGap),
                          const _LockedCardColumn(),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCardColumn extends StatelessWidget {
  final ModeInfo top, bottom;
  final void Function(ModeInfo) onTap;
  final int colIndex;
  final AnimationController ctrl;

  const _ModeCardColumn({
    required this.top,
    required this.bottom,
    required this.onTap,
    required this.colIndex,
    required this.ctrl,
  });

  Animation<double> _fade(int i) => CurvedAnimation(
        parent: ctrl,
        curve: Interval(i * 0.15, (i * 0.15 + 0.6).clamp(0, 1),
            curve: Curves.easeOut),
      );

  Animation<Offset> _slide(int i) => Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: ctrl,
        curve: Interval(i * 0.15, (i * 0.15 + 0.6).clamp(0, 1),
            curve: Curves.easeOut),
      ));

  @override
  Widget build(BuildContext context) {
    final topIdx = colIndex * 2;
    final botIdx = colIndex * 2 + 1;
    return Column(
      children: [
        FadeTransition(
          opacity: _fade(topIdx),
          child: SlideTransition(
            position: _slide(topIdx),
            child: SizedBox(
              width: _kCardSize, height: _kCardSize,
              child: ModeCard(modeInfo: top, index: topIdx, onTap: () => onTap(top)),
            ),
          ),
        ),
        const SizedBox(height: _kCardGap),
        FadeTransition(
          opacity: _fade(botIdx),
          child: SlideTransition(
            position: _slide(botIdx),
            child: SizedBox(
              width: _kCardSize, height: _kCardSize,
              child: ModeCard(modeInfo: bottom, index: botIdx, onTap: () => onTap(bottom)),
            ),
          ),
        ),
      ],
    );
  }
}

/// 상단: 활성 카드 1개, 하단: 잠금 카드 1개
class _MixedCardColumn extends StatelessWidget {
  final ModeInfo top;
  final void Function(ModeInfo) onTap;
  final int colIndex;
  final AnimationController ctrl;

  const _MixedCardColumn({
    required this.top,
    required this.onTap,
    required this.colIndex,
    required this.ctrl,
  });

  Animation<double> _fade(int i) => CurvedAnimation(
        parent: ctrl,
        curve: Interval(i * 0.15, (i * 0.15 + 0.6).clamp(0, 1),
            curve: Curves.easeOut),
      );

  Animation<Offset> _slide(int i) => Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: ctrl,
        curve: Interval(i * 0.15, (i * 0.15 + 0.6).clamp(0, 1),
            curve: Curves.easeOut),
      ));

  @override
  Widget build(BuildContext context) {
    final topIdx = colIndex * 2;
    return Column(
      children: [
        FadeTransition(
          opacity: _fade(topIdx),
          child: SlideTransition(
            position: _slide(topIdx),
            child: SizedBox(
              width: _kCardSize, height: _kCardSize,
              child: ModeCard(modeInfo: top, index: topIdx, onTap: () => onTap(top)),
            ),
          ),
        ),
        const SizedBox(height: _kCardGap),
        const _LockedCard(),
      ],
    );
  }
}

class _LockedCardColumn extends StatelessWidget {
  const _LockedCardColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _LockedCard(),
        const SizedBox(height: _kCardGap),
        const _LockedCard(),
      ],
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kCardSize,
      height: _kCardSize,
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 42, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            '오픈 예정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
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
        Flexible(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: SvgPicture.asset(
              'assets/main/main-character.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: _kPrimary.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
          ],
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
