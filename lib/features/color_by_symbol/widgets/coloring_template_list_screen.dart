import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/color_by_symbol/models/coloring_template.dart';

/// 7.1 색칠 도안 목록 화면 (썸네일 그리드)
class ColoringTemplateListScreen extends StatelessWidget {
  final void Function(ColoringTemplate) onSelected;

  const ColoringTemplateListScreen({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('숫자로 색칠하기'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '색칠할 그림을 골라봐요! 🎨',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemCount: ColoringTemplate.registry.length,
                itemBuilder: (context, i) {
                  final tmpl = ColoringTemplate.registry[i];
                  return _TemplateCard(
                    template: tmpl,
                    onTap: () => onSelected(tmpl),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ColoringTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: template.thumbnailColor.withValues(alpha: 0.3),
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 3),
              blurRadius: 10,
            ),
          ],
          border: Border.all(color: Colors.white, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: template.thumbnailColor.withValues(alpha: 0.1),
                child: CustomPaint(
                  painter: _ThumbnailPainter(template),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                template.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 썸네일 미리보기: 윤곽선만 표시
class _ThumbnailPainter extends CustomPainter {
  final ColoringTemplate template;
  const _ThumbnailPainter(this.template);

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in template.regions) {
      final path = region.pathBuilder(size);
      // 연한 hint 색 배경
      canvas.drawPath(
        path,
        Paint()
          ..color = region.hintColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      // 윤곽선
      canvas.drawPath(
        path,
        Paint()
          ..color = region.hintColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_ThumbnailPainter old) => old.template != template;
}
