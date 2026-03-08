import 'dart:math';
import 'package:flutter/material.dart';

/// 선 따라 그리기 가이드 선 템플릿.
/// [pathBuilder]는 캔버스 Size를 받아 실제 그릴 Path를 반환.
/// 템플릿 데이터는 코드에 내장(embedded)되어 있음 — 6.2.
class TraceTemplate {
  final String id;
  final String name;
  final Color thumbnailColor;
  final Path Function(Size) pathBuilder;

  const TraceTemplate({
    required this.id,
    required this.name,
    required this.thumbnailColor,
    required this.pathBuilder,
  });

  /// 내장 템플릿 레지스트리.
  static final List<TraceTemplate> registry = [
    TraceTemplate(
      id: 'straight',
      name: '직선',
      thumbnailColor: const Color(0xFFFF6B6B),
      pathBuilder: _straightPath,
    ),
    TraceTemplate(
      id: 'wave',
      name: '물결선',
      thumbnailColor: const Color(0xFF4FC3F7),
      pathBuilder: _wavePath,
    ),
    TraceTemplate(
      id: 'zigzag',
      name: '지그재그',
      thumbnailColor: const Color(0xFF66BB6A),
      pathBuilder: _zigzagPath,
    ),
    TraceTemplate(
      id: 'circle',
      name: '원',
      thumbnailColor: const Color(0xFFFF8A65),
      pathBuilder: _circlePath,
    ),
    TraceTemplate(
      id: 'star',
      name: '별',
      thumbnailColor: const Color(0xFFFFCA28),
      pathBuilder: _starPath,
    ),
    TraceTemplate(
      id: 'heart',
      name: '하트',
      thumbnailColor: const Color(0xFFEC407A),
      pathBuilder: _heartPath,
    ),
  ];

  // ── 경로 빌더 함수들 ───────────────────────────────────

  static Path _straightPath(Size s) => Path()
    ..moveTo(s.width * 0.1, s.height * 0.5)
    ..lineTo(s.width * 0.9, s.height * 0.5);

  static Path _wavePath(Size s) {
    final path = Path()..moveTo(s.width * 0.05, s.height * 0.5);
    const steps = 6;
    for (int i = 0; i < steps; i++) {
      final base = 0.05 + i / steps * 0.9;
      final x1 = s.width * (base + 0.25 / steps * 0.9);
      final y1 = s.height * (i.isEven ? 0.2 : 0.8);
      final x2 = s.width * (base + 0.5 / steps * 0.9);
      final y2 = s.height * (i.isEven ? 0.2 : 0.8);
      final x3 = s.width * (base + 1.0 / steps * 0.9);
      final y3 = s.height * 0.5;
      path.cubicTo(x1, y1, x2, y2, x3, y3);
    }
    return path;
  }

  static Path _zigzagPath(Size s) {
    const steps = 6;
    final path = Path()..moveTo(s.width * 0.05, s.height * 0.5);
    for (int i = 0; i < steps; i++) {
      path.lineTo(
        s.width * (0.05 + (i + 1) / steps * 0.9),
        s.height * (i.isEven ? 0.2 : 0.8),
      );
    }
    path.lineTo(s.width * 0.95, s.height * 0.5);
    return path;
  }

  static Path _circlePath(Size s) {
    final r = s.shortestSide * 0.36;
    return Path()
      ..addOval(Rect.fromCircle(
        center: Offset(s.width * 0.5, s.height * 0.5),
        radius: r,
      ));
  }

  static Path _starPath(Size s) {
    final cx = s.width * 0.5;
    final cy = s.height * 0.5;
    final outer = s.shortestSide * 0.42;
    final inner = outer * 0.4;
    const pts = 5;
    final path = Path();
    for (int i = 0; i < pts * 2; i++) {
      final r = i.isEven ? outer : inner;
      final angle = (i * pi / pts) - pi / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Path _heartPath(Size s) {
    final cx = s.width * 0.5;
    final cy = s.height * 0.45;
    final w = s.width * 0.7;
    final h = s.height * 0.65;
    return Path()
      ..moveTo(cx, cy + h * 0.35)
      ..cubicTo(
        cx - w * 0.6, cy + h * 0.1,
        cx - w * 0.6, cy - h * 0.4,
        cx, cy - h * 0.1,
      )
      ..cubicTo(
        cx + w * 0.6, cy - h * 0.4,
        cx + w * 0.6, cy + h * 0.1,
        cx, cy + h * 0.35,
      )
      ..close();
  }
}
