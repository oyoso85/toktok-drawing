import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 색칠 도안의 개별 영역.
/// [symbol]: 영역에 표시할 기호 ('1', '2', '3' …)
/// [hintColor]: 권장 색상 (가이드용)
/// [pathBuilder]: 캔버스 크기를 받아 닫힌 Path를 반환
/// [textPositionBuilder]: 기호 텍스트 위치 (null이면 path 경계 중심 사용)
class ColoringRegion {
  final String symbol;
  final Color hintColor;
  final Path Function(Size) pathBuilder;
  final Offset Function(Size)? textPositionBuilder;

  ColoringRegion({
    required this.symbol,
    required this.hintColor,
    required this.pathBuilder,
    this.textPositionBuilder,
  });
}

/// 색칠 도안 템플릿.
/// 영역 목록은 렌더링 순서(아래→위)로 나열 — hit test는 역순(위→아래)으로 수행.
class ColoringTemplate {
  final String id;
  final String name;
  final Color thumbnailColor;
  final List<ColoringRegion> regions;

  ColoringTemplate({
    required this.id,
    required this.name,
    required this.thumbnailColor,
    required this.regions,
  });

  static final List<ColoringTemplate> registry = [
    _rainbow,
    _house,
    _tree,
    _sun,
    _rocket,
    _flower,
    _butterfly,
  ];

  // ── 1. 무지개 ─────────────────────────────────────────────

  static final _rainbow = ColoringTemplate(
    id: 'rainbow',
    name: '무지개',
    thumbnailColor: const Color(0xFFE53935),
    regions: [
      ColoringRegion(
        symbol: '4',
        hintColor: const Color(0xFF43A047), // 초록 (가장 바깥)
        pathBuilder: (s) => _rainbowBand(s, 0.39, 0.47),
      ),
      ColoringRegion(
        symbol: '3',
        hintColor: const Color(0xFFFFEB3B), // 노랑
        pathBuilder: (s) => _rainbowBand(s, 0.31, 0.39),
      ),
      ColoringRegion(
        symbol: '2',
        hintColor: const Color(0xFFFF9800), // 주황
        pathBuilder: (s) => _rainbowBand(s, 0.23, 0.31),
      ),
      ColoringRegion(
        symbol: '1',
        hintColor: const Color(0xFFE53935), // 빨강 (가장 안쪽)
        pathBuilder: (s) => _rainbowBand(s, 0.14, 0.23),
      ),
    ],
  );

  /// 반원 호 띠: center (w/2, h*0.78), 반지름 비율 기준
  static Path _rainbowBand(Size size, double rInnerRatio, double rOuterRatio) {
    final cx = size.width / 2;
    final cy = size.height * 0.78;
    final ri = rInnerRatio * size.width;
    final ro = rOuterRatio * size.width;
    return Path()
      ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: ro), math.pi, math.pi, false)
      ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: ri), 0, -math.pi, false)
      ..close();
  }

  // ── 2. 집 ────────────────────────────────────────────────

  static final _house = ColoringTemplate(
    id: 'house',
    name: '집',
    thumbnailColor: const Color(0xFFEF5350),
    regions: [
      ColoringRegion(
        symbol: '1',
        hintColor: const Color(0xFFEF5350), // 빨간 지붕
        pathBuilder: (s) {
          final w = s.width, h = s.height;
          return Path()
            ..moveTo(w * 0.15, h * 0.46)
            ..lineTo(w * 0.50, h * 0.12)
            ..lineTo(w * 0.85, h * 0.46)
            ..close();
        },
      ),
      ColoringRegion(
        symbol: '2',
        hintColor: const Color(0xFFFFF176), // 노란 벽
        pathBuilder: (s) {
          final w = s.width, h = s.height;
          return Path()
            ..addRect(Rect.fromLTWH(w * 0.18, h * 0.44, w * 0.64, h * 0.44));
        },
      ),
      ColoringRegion(
        symbol: '3',
        hintColor: const Color(0xFF8D6E63), // 갈색 문
        pathBuilder: (s) {
          final w = s.width, h = s.height;
          return Path()
            ..addRect(Rect.fromLTWH(w * 0.40, h * 0.63, w * 0.20, h * 0.25));
        },
      ),
    ],
  );

  // ── 3. 나무 ──────────────────────────────────────────────

  static final _tree = ColoringTemplate(
    id: 'tree',
    name: '나무',
    thumbnailColor: const Color(0xFF2E7D32),
    regions: [
      ColoringRegion(
        symbol: '1',
        hintColor: const Color(0xFF2E7D32), // 초록 나뭇잎
        pathBuilder: (s) {
          final w = s.width, h = s.height;
          return Path()
            ..moveTo(w * 0.50, h * 0.05)
            ..lineTo(w * 0.12, h * 0.62)
            ..lineTo(w * 0.88, h * 0.62)
            ..close();
        },
      ),
      ColoringRegion(
        symbol: '2',
        hintColor: const Color(0xFF8D6E63), // 갈색 기둥
        pathBuilder: (s) {
          final w = s.width, h = s.height;
          return Path()
            ..addRect(Rect.fromLTWH(w * 0.38, h * 0.60, w * 0.24, h * 0.36));
        },
      ),
    ],
  );

  // ── 4. 태양 ──────────────────────────────────────────────

  static final _sun = ColoringTemplate(
    id: 'sun',
    name: '태양',
    thumbnailColor: const Color(0xFFFF8F00),
    regions: [
      ColoringRegion(
        symbol: '1',
        hintColor: const Color(0xFFFF8F00), // 주황 광선
        pathBuilder: _sunRays,
      ),
      ColoringRegion(
        symbol: '2',
        hintColor: const Color(0xFFFFEB3B), // 노란 원판
        pathBuilder: (s) {
          final cx = s.width / 2, cy = s.height / 2;
          return Path()
            ..addOval(Rect.fromCenter(
                center: Offset(cx, cy),
                width: s.width * 0.44,
                height: s.width * 0.44));
        },
      ),
    ],
  );

  /// 8-pointed star (광선) path
  static Path _sunRays(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const n = 8;
    final outerR = size.width * 0.40;
    final innerR = size.width * 0.22;
    final path = Path();
    for (int i = 0; i < n * 2; i++) {
      final angle = i * math.pi / n - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  // ── 5. 로켓 ──────────────────────────────────────────────

  static final _rocket = ColoringTemplate(
    id: 'rocket',
    name: '로켓',
    thumbnailColor: const Color(0xFF1565C0),
    regions: [
      ColoringRegion(
        symbol: '1',
        hintColor: const Color(0xFF1565C0), // 파란 몸체
        pathBuilder: (s) {
          final w = s.width, h = s.height;
          return Path()
            ..moveTo(w * 0.50, h * 0.05) // 꼭대기
            ..lineTo(w * 0.65, h * 0.35) // 오른쪽 어깨
            ..lineTo(w * 0.65, h * 0.72) // 오른쪽 아래
            ..lineTo(w * 0.35, h * 0.72) // 왼쪽 아래
            ..lineTo(w * 0.35, h * 0.35) // 왼쪽 어깨
            ..close();
        },
      ),
      ColoringRegion(
        symbol: '3',
        hintColor: const Color(0xFFFF7043), // 주황 화염
        pathBuilder: (s) {
          final w = s.width, h = s.height;
          return Path()
            ..moveTo(w * 0.50, h * 0.95) // 불꽃 끝
            ..lineTo(w * 0.35, h * 0.72)
            ..lineTo(w * 0.65, h * 0.72)
            ..close();
        },
      ),
      ColoringRegion(
        symbol: '2',
        hintColor: const Color(0xFF80DEEA), // 하늘색 창문
        pathBuilder: (s) {
          final cx = s.width / 2, cy = s.height * 0.42;
          return Path()
            ..addOval(Rect.fromCenter(
                center: Offset(cx, cy),
                width: s.width * 0.22,
                height: s.width * 0.22));
        },
      ),
    ],
  );

  // ── 6. 꽃 ────────────────────────────────────────────────

  static final _flower = ColoringTemplate(
    id: 'flower',
    name: '꽃',
    thumbnailColor: const Color(0xFFE91E63),
    regions: [
      ColoringRegion(
        symbol: '3',
        hintColor: const Color(0xFF43A047), // 초록 줄기
        pathBuilder: (s) {
          final w = s.width, h = s.height;
          return Path()
            ..addRect(Rect.fromLTWH(w * 0.46, h * 0.60, w * 0.08, h * 0.36));
        },
      ),
      ColoringRegion(
        symbol: '1',
        hintColor: const Color(0xFFE91E63), // 분홍 꽃잎
        pathBuilder: (s) {
          final cx = s.width / 2, cy = s.height * 0.38;
          final r = s.width * 0.13;
          final d = s.width * 0.21;
          final path = Path();
          for (int i = 0; i < 5; i++) {
            final angle = i * 2 * math.pi / 5 - math.pi / 2;
            path.addOval(Rect.fromCenter(
              center: Offset(cx + d * math.cos(angle), cy + d * math.sin(angle)),
              width: r * 2,
              height: r * 2,
            ));
          }
          return path;
        },
        // 꽃잎 기호는 위쪽 꽃잎 중심에 표시
        textPositionBuilder: (s) =>
            Offset(s.width / 2, s.height * 0.38 - s.width * 0.21),
      ),
      ColoringRegion(
        symbol: '2',
        hintColor: const Color(0xFFFFEB3B), // 노란 꽃심
        pathBuilder: (s) {
          final cx = s.width / 2, cy = s.height * 0.38;
          return Path()
            ..addOval(Rect.fromCenter(
                center: Offset(cx, cy),
                width: s.width * 0.18,
                height: s.width * 0.18));
        },
      ),
    ],
  );

  // ── 7. 나비 ──────────────────────────────────────────────

  static final _butterfly = ColoringTemplate(
    id: 'butterfly',
    name: '나비',
    thumbnailColor: const Color(0xFF7B1FA2),
    regions: [
      ColoringRegion(
        symbol: '1',
        hintColor: const Color(0xFF7B1FA2), // 보라 왼쪽 날개
        pathBuilder: (s) {
          final cx = s.width / 2, cy = s.height / 2;
          return Path()
            ..addOval(Rect.fromCenter(
                center: Offset(cx - s.width * 0.24, cy - s.height * 0.14),
                width: s.width * 0.42,
                height: s.height * 0.32))
            ..addOval(Rect.fromCenter(
                center: Offset(cx - s.width * 0.20, cy + s.height * 0.20),
                width: s.width * 0.30,
                height: s.height * 0.24));
        },
        textPositionBuilder: (s) =>
            Offset(s.width / 2 - s.width * 0.24, s.height / 2 - s.height * 0.14),
      ),
      ColoringRegion(
        symbol: '2',
        hintColor: const Color(0xFFE91E63), // 분홍 오른쪽 날개
        pathBuilder: (s) {
          final cx = s.width / 2, cy = s.height / 2;
          return Path()
            ..addOval(Rect.fromCenter(
                center: Offset(cx + s.width * 0.24, cy - s.height * 0.14),
                width: s.width * 0.42,
                height: s.height * 0.32))
            ..addOval(Rect.fromCenter(
                center: Offset(cx + s.width * 0.20, cy + s.height * 0.20),
                width: s.width * 0.30,
                height: s.height * 0.24));
        },
        textPositionBuilder: (s) =>
            Offset(s.width / 2 + s.width * 0.24, s.height / 2 - s.height * 0.14),
      ),
      ColoringRegion(
        symbol: '3',
        hintColor: const Color(0xFF212121), // 검정 몸통
        pathBuilder: (s) {
          final cx = s.width / 2, cy = s.height / 2;
          return Path()
            ..addOval(Rect.fromCenter(
                center: Offset(cx, cy),
                width: s.width * 0.09,
                height: s.height * 0.55));
        },
      ),
    ],
  );
}
