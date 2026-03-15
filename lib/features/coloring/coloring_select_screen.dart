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

class ColoringSelectScreen extends StatelessWidget {
  const ColoringSelectScreen({super.key});

  void _openTemplate(BuildContext context, SvgTemplate template) {
    final index = kSvgTemplates.indexOf(template);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ColoringScreen(
        svgAssetPath: template.assetPath,
        allTemplates: kSvgTemplates,
        templateIndex: index,
      ),
    ));
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
                onTap: (t) => _openTemplate(context, t),
              ),
              const SizedBox(height: 12),
              _TemplateRow(
                templates: row2,
                onTap: (t) => _openTemplate(context, t),
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

  const _TemplateRow({required this.templates, required this.onTap});

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
            onTap: () => onTap(templates[i]),
          ),
        ],
      ],
    );
  }
}

// ── 개별 카드 ─────────────────────────────────────────────────────────────────

class _SvgTemplateCard extends StatelessWidget {
  static const double size = 150.0;      // 카드 전체 크기 (정사각형)
  static const double padding = 16.0;   // 마운트 여백

  final SvgTemplate template;
  final VoidCallback onTap;

  const _SvgTemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
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
        padding: const EdgeInsets.all(padding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: Colors.white,
            child: _SvgThumbnail(assetPath: template.assetPath),
          ),
        ),
      ),
    );
  }
}

// ── SVG 썸네일 렌더러 ─────────────────────────────────────────────────────────

class _SvgThumbnail extends StatefulWidget {
  final String assetPath;

  const _SvgThumbnail({required this.assetPath});

  @override
  State<_SvgThumbnail> createState() => _SvgThumbnailState();
}

class _SvgThumbnailState extends State<_SvgThumbnail> {
  List<ColoringPath>? _paths;
  Size _svgViewBox = const Size(630, 648);

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    final svgString = await rootBundle.loadString(widget.assetPath);
    final paths = SvgColoringParser.parse(svgString);
    final viewBox = SvgColoringParser.parseViewBox(svgString);
    if (mounted) {
      setState(() {
        _paths = paths;
        _svgViewBox = viewBox;
      });
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
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}
