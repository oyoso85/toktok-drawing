import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';

/// 선 따라 그리기 도안 선택 화면.
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
              _TemplateRow(templates: row1, startIndex: 0, onTap: onSelected),
              const SizedBox(height: 12),
              _TemplateRow(templates: row2, startIndex: 1, onTap: onSelected),
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
  final int startIndex;

  const _TemplateRow({
    required this.templates,
    required this.onTap,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) return const SizedBox(width: _TraceTemplateCard.size);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < templates.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          _TraceTemplateCard(
            template: templates[i],
            cardIndex: startIndex + i,
            onTap: () => onTap(templates[i]),
          ),
        ],
      ],
    );
  }
}

/// 애니메이션 타입:
///   0 → 천천히 커졌다 돌아오기 (scale pulse)
///   1 → 좌우 살짝 기울기 (tilt rotation)
///   2 → 둥둥 떠 있는 느낌 (float up-down)
class _TraceTemplateCard extends StatefulWidget {
  static const double size = 300.0;
  static const double padding = 16.0;

  final TraceTemplate template;
  final VoidCallback onTap;
  final int cardIndex;

  const _TraceTemplateCard({
    required this.template,
    required this.onTap,
    required this.cardIndex,
  });

  @override
  State<_TraceTemplateCard> createState() => _TraceTemplateCardState();
}

class _TraceTemplateCardState extends State<_TraceTemplateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  static const _durations = [2200, 1800, 2600];

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
          case 0:
            card = Transform.scale(scale: 1.0 + _anim.value * 0.04, child: card);
          case 1:
            final angle = (_anim.value - 0.5) * 2 * 0.044;
            card = Transform.rotate(angle: angle, child: card);
          case 2:
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
          width: _TraceTemplateCard.size,
          height: _TraceTemplateCard.size,
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
          padding: const EdgeInsets.all(_TraceTemplateCard.padding),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: widget.template.thumbnailColor.withValues(alpha: 0.10),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        widget.template.svgAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.template.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
