import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/color_by_symbol/models/coloring_template.dart';

/// 7.3 + 7.4 + 7.6 색칠 캔버스.
/// - 영역별 색상 채우기 / 윤곽선 / 기호 텍스트 표시
/// - 탭 hit test: 상위 영역(나중에 그린)부터 확인
class ColoringCanvas extends StatelessWidget {
  final ColoringTemplate template;
  final Map<int, Color> filledRegions;
  final void Function(int regionIndex) onTap;

  const ColoringCanvas({
    super.key,
    required this.template,
    required this.filledRegions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapDown: (details) {
            final pos = details.localPosition;
            // 역순 탐색: 나중에 그린 영역(위에 보이는)이 먼저 hit
            for (int i = template.regions.length - 1; i >= 0; i--) {
              final path = template.regions[i].pathBuilder(size);
              if (path.contains(pos)) {
                onTap(i);
                return;
              }
            }
          },
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _ColoringPainter(
                template: template,
                filledRegions: filledRegions,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _ColoringPainter extends CustomPainter {
  final ColoringTemplate template;
  final Map<int, Color> filledRegions;

  const _ColoringPainter({
    required this.template,
    required this.filledRegions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 흰 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    for (int i = 0; i < template.regions.length; i++) {
      final region = template.regions[i];
      final path = region.pathBuilder(size);
      final fillColor = filledRegions[i];

      // 채우기 (채워진 경우 실제 색, 미채워진 경우 hint 연한 배경)
      canvas.drawPath(
        path,
        Paint()
          ..color = fillColor ?? region.hintColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );

      // 윤곽선
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black45
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );

      // 7.4 기호 표시: 미채워진 영역에만 숫자 표시
      if (fillColor == null) {
        _drawSymbol(canvas, path, region, size);
      }
    }
  }

  void _drawSymbol(Canvas canvas, Path path, ColoringRegion region, Size size) {
    final center = region.textPositionBuilder != null
        ? region.textPositionBuilder!(size)
        : path.getBounds().center;

    final tp = TextPainter(
      text: TextSpan(
        text: region.symbol,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ColoringPainter old) =>
      old.template != template || old.filledRegions != filledRegions;
}
