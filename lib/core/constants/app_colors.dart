import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFEEBD2B); // 레퍼런스 골든 옐로우
  static const Color background = Color(0xFFF8F7F6); // 레퍼런스 배경

  /// 꽃씨 붓 "무지개" 모드 센티넬 값 (실제 색상이 아닌 식별용)
  static const Color kRainbow = Color(0x01FFFFFF);

  // 드로잉 팔레트 기본 색상 (10색 + 무지개)
  static const List<Color> palette = [
    Color(0xFFFF0000), // 빨강
    Color(0xFFFF8C00), // 주황
    Color(0xFFFFD700), // 노랑
    Color(0xFF32CD32), // 초록
    Color(0xFF1E90FF), // 파랑
    Color(0xFF8A2BE2), // 보라
    Color(0xFFFF69B4), // 분홍
    Color(0xFF8B4513), // 갈색
    Color(0xFF000000), // 검정
    Color(0xFFFFFFFF), // 흰색
    Color(0x01FFFFFF), // 무지개 (꽃씨 붓용 센티넬)
  ];

  // 모드 카드 배경 색상 (이미지 없을 때 플레이스홀더) — 채도 강화
  static const List<Color> modeCardBg = [
    Color(0xFFFFB74D), // 자유그리기 - 주황
    Color(0xFF81C784), // 선따라 - 초록
    Color(0xFF64B5F6), // 색칠 - 파랑
    Color(0xFFCE93D8), // 대칭 - 보라
  ];
}
