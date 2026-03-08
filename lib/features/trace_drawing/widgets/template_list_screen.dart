import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';

/// 6.1 가이드 선 템플릿 목록 화면.
/// 탭 시 [onSelected] 콜백으로 선택된 템플릿을 반환.
class TemplateListScreen extends StatelessWidget {
  final void Function(TraceTemplate) onSelected;

  const TemplateListScreen({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('선 따라 그리기'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '따라 그릴 선을 골라봐요! ✏️',
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
                itemCount: TraceTemplate.registry.length,
                itemBuilder: (context, i) {
                  final tmpl = TraceTemplate.registry[i];
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
  final TraceTemplate template;
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
            // 썸네일 미리보기
            Expanded(
              child: Container(
                color: template.thumbnailColor.withValues(alpha: 0.12),
                child: CustomPaint(
                  painter: _TemplateThumbnailPainter(template),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // 이름
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

/// 템플릿 카드 썸네일 미리보기 Painter.
class _TemplateThumbnailPainter extends CustomPainter {
  final TraceTemplate template;
  const _TemplateThumbnailPainter(this.template);

  @override
  void paint(Canvas canvas, Size size) {
    final path = template.pathBuilder(size);
    final paint = Paint()
      ..color = template.thumbnailColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 점선 미리보기
    _drawDashed(canvas, path, paint);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 10.0;
    const gap = 6.0;
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double d = 0;
      bool draw = true;
      while (d < metric.length) {
        final len = draw ? dash : gap;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(d, (d + len).clamp(0, metric.length)),
            paint,
          );
        }
        d += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_TemplateThumbnailPainter old) =>
      old.template != template;
}
