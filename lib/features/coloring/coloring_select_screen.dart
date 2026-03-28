import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/features/coloring/coloring_screen.dart';
import 'package:toktok_drawing/features/coloring/data/svg_template_registry.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_path.dart';
import 'package:toktok_drawing/features/coloring/models/coloring_transform.dart';
import 'package:toktok_drawing/features/coloring/models/svg_coloring_parser.dart';
import 'package:toktok_drawing/features/coloring/models/svg_template.dart';
import 'package:toktok_drawing/features/coloring/painters/coloring_thumbnail_painter.dart';
import 'package:toktok_drawing/features/coloring/services/coloring_progress_service.dart';

class ColoringSelectScreen extends StatefulWidget {
  const ColoringSelectScreen({super.key});

  @override
  State<ColoringSelectScreen> createState() => _ColoringSelectScreenState();
}

class _ColoringSelectScreenState extends State<ColoringSelectScreen> {
  /// 마지막으로 열었던 템플릿의 assetPath. 돌아왔을 때 해당 썸네일만 갱신.
  String? _lastOpenedPath;
  int _refreshCounter = 0;

  void _openTemplate(BuildContext context, SvgTemplate template) {
    final index = kSvgTemplates.indexOf(template);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ColoringScreen(
        svgAssetPath: template.assetPath,
        allTemplates: kSvgTemplates,
        templateIndex: index,
      ),
    )).then((_) {
      setState(() {
        _lastOpenedPath = template.assetPath;
        _refreshCounter++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2행 분배: 짝수 인덱스 → 위 행, 홀수 인덱스 → 아래 행 (컬럼 우선)
    final templates = kSvgTemplates;
    final row1 = [
      for (int i = 0; i < templates.length; i += 2) templates[i],
    ];
    final row2 = [
      for (int i = 1; i < templates.length; i += 2) templates[i],
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '색칠하기',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TemplateRow(
                templates: row1,
                startIndex: 0,
                onTap: (t) => _openTemplate(context, t),
                lastOpenedPath: _lastOpenedPath,
                refreshCounter: _refreshCounter,
              ),
              const SizedBox(height: 12),
              _TemplateRow(
                templates: row2,
                startIndex: 1,
                onTap: (t) => _openTemplate(context, t),
                lastOpenedPath: _lastOpenedPath,
                refreshCounter: _refreshCounter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 한 행의 카드 나열 ─────────────────────────────────────────────────────────

class _TemplateRow extends StatelessWidget {
  final List<SvgTemplate> templates;
  final void Function(SvgTemplate) onTap;
  final int startIndex;
  final String? lastOpenedPath;
  final int refreshCounter;

  const _TemplateRow({
    required this.templates,
    required this.onTap,
    this.startIndex = 0,
    this.lastOpenedPath,
    this.refreshCounter = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) return const SizedBox(width: _SvgTemplateCard.size);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < templates.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          _SvgTemplateCard(
            template: templates[i],
            cardIndex: startIndex + i,
            onTap: () => onTap(templates[i]),
            thumbnailRefreshKey:
                lastOpenedPath == templates[i].assetPath ? refreshCounter : 0,
          ),
        ],
      ],
    );
  }
}

// ── 개별 카드 ─────────────────────────────────────────────────────────────────

/// 애니메이션 타입:
///   0 → 천천히 커졌다 돌아오기 (scale pulse)
///   1 → 좌우 살짝 기울기 (tilt rotation)
///   2 → 둥둥 떠 있는 느낌 (float up-down)
class _SvgTemplateCard extends StatefulWidget {
  static const double size = 300.0;
  static const double padding = 16.0;

  final SvgTemplate template;
  final VoidCallback onTap;
  final int cardIndex;
  final int thumbnailRefreshKey;

  const _SvgTemplateCard({
    required this.template,
    required this.onTap,
    required this.cardIndex,
    this.thumbnailRefreshKey = 0,
  });

  @override
  State<_SvgTemplateCard> createState() => _SvgTemplateCardState();
}

class _SvgTemplateCardState extends State<_SvgTemplateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  // 그룹(0~2)별 duration 및 딜레이 설정
  static const _durations = [2200, 1800, 2600]; // ms: scale, tilt, float

  @override
  void initState() {
    super.initState();
    final group = widget.cardIndex % 3;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durations[group]),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    final delay = Random().nextInt(1000);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animType = widget.cardIndex % 3;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        Widget card = child!;
        switch (animType) {
          case 0: // scale pulse: 1.0 → 1.04
            card = Transform.scale(
              scale: 1.0 + _anim.value * 0.04,
              child: card,
            );
          case 1: // tilt rotation: -2.5° ↔ +2.5°
            final angle = (_anim.value - 0.5) * 2 * 0.044; // ~±2.5°
            card = Transform.rotate(angle: angle, child: card);
          case 2: // float: -7px ↔ +7px
            card = Transform.translate(
              offset: Offset(0, (_anim.value - 0.5) * 2 * 7.0),
              child: card,
            );
        }
        return card;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: _SvgTemplateCard.size,
          height: _SvgTemplateCard.size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(_SvgTemplateCard.padding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: Colors.white,
              child: _SvgThumbnail(
                assetPath: widget.template.assetPath,
                refreshKey: widget.thumbnailRefreshKey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── SVG 썸네일 렌더러 ─────────────────────────────────────────────────────────

class _SvgThumbnail extends StatefulWidget {
  final String assetPath;
  final int refreshKey;

  const _SvgThumbnail({required this.assetPath, this.refreshKey = 0});

  @override
  State<_SvgThumbnail> createState() => _SvgThumbnailState();
}

class _SvgThumbnailState extends State<_SvgThumbnail> {
  List<ColoringPath>? _paths;
  Size _svgViewBox = const Size(630, 648);
  Map<int, Color>? _filledPaths;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  @override
  void didUpdateWidget(_SvgThumbnail old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) {
      _refreshProgress();
    }
  }

  Future<void> _loadPaths() async {
    try {
      final svgString = await rootBundle.loadString(widget.assetPath);
      final paths = SvgColoringParser.parse(svgString);
      final viewBox = SvgColoringParser.parseViewBox(svgString);
      final filledPaths =
          await ColoringProgressService.instance.loadCompleted(widget.assetPath);
      if (mounted) {
        setState(() {
          _paths = paths;
          _svgViewBox = viewBox;
          _filledPaths = filledPaths;
        });
      }
    } catch (e) {
      debugPrint('[Thumbnail] SVG 로드 실패 ${widget.assetPath}: $e');
    }
  }

  /// 색칠 완료 후 복귀 시 progress만 갱신 (SVG 재파싱 없음).
  Future<void> _refreshProgress() async {
    try {
      final filledPaths =
          await ColoringProgressService.instance.loadCompleted(widget.assetPath);
      if (mounted) setState(() => _filledPaths = filledPaths);
    } catch (e) {
      debugPrint('[Thumbnail] progress 갱신 실패 ${widget.assetPath}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paths == null) {
      return const SizedBox.expand();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final transform = ColoringTransform.forCanvas(
          Size(constraints.maxWidth, constraints.maxHeight),
          svgViewBox: _svgViewBox,
        );
        return CustomPaint(
          painter: ColoringThumbnailPainter(
            paths: _paths!,
            transformMatrix: transform.storage,
            filledPaths: _filledPaths,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}
