import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';

/// 선 따라 그리기 도안 선택 화면.
/// ColoringSelectScreen과 동일한 마운트 카드 스타일 (150×150, 2행 가로 스크롤).
class TemplateListScreen extends StatelessWidget {
  final List<TraceTemplate> templates;
  final void Function(TraceTemplate) onSelected;

  const TemplateListScreen({
    super.key,
    required this.templates,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final row1 = [for (int i = 0; i < templates.length; i += 2) templates[i]];
    final row2 = [for (int i = 1; i < templates.length; i += 2) templates[i]];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '선 따라 그리기',
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
              _TemplateRow(templates: row1, onTap: onSelected),
              const SizedBox(height: 12),
              _TemplateRow(templates: row2, onTap: onSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final List<TraceTemplate> templates;
  final void Function(TraceTemplate) onTap;

  const _TemplateRow({required this.templates, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) return const SizedBox(width: _TraceTemplateCard.size);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < templates.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          _TraceTemplateCard(template: templates[i], onTap: () => onTap(templates[i])),
        ],
      ],
    );
  }
}

class _TraceTemplateCard extends StatelessWidget {
  static const double size = 150.0;
  static const double padding = 16.0;

  final TraceTemplate template;
  final VoidCallback onTap;

  const _TraceTemplateCard({required this.template, required this.onTap});

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
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: template.thumbnailColor.withValues(alpha: 0.10),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset(
                      template.svgAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              template.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

