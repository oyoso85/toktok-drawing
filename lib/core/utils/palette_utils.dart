import 'dart:math';
import 'package:flutter/material.dart' show HSLColor, Color;
import 'package:toktok_drawing/core/constants/app_colors.dart';

/// 빨주노초파남보 7색
const List<Color> rainbowColors = [
  Color(0xFFFF0000), // 빨
  Color(0xFFFF7F00), // 주
  Color(0xFFFFEE00), // 노
  Color(0xFF00CC44), // 초
  Color(0xFF1E90FF), // 파
  Color(0xFF4B0082), // 남
  Color(0xFF8B00FF), // 보
];

/// 꽃씨 붓용 팔레트 생성.
/// - baseColor == AppColors.kRainbow: 빨주노초파남보 7색 반환
/// - 그 외: 선택 색상의 hue를 기준으로 ±40° 유사색 4~5개 반환
List<Color> generateSparklePalette(Color baseColor) {
  if (baseColor == AppColors.kRainbow) {
    return List.from(rainbowColors);
  }

  final rng = Random();
  final hsl = HSLColor.fromColor(baseColor);
  final baseHue = hsl.hue;
  final count = 4 + rng.nextInt(2); // 4 또는 5개

  return List.generate(count, (i) {
    // ±40° 범위에서 고르게 분산 (예: 5개면 -40,-20,0,+20,+40)
    final spread = 80.0; // 전체 각도 범위
    final offset = (i / (count - 1)) * spread - spread / 2;
    final hue = (baseHue + offset + 360) % 360;

    final saturation = 0.75 + rng.nextDouble() * 0.17; // 0.75~0.92
    final lightness = 0.48 + rng.nextDouble() * 0.17;  // 0.48~0.65

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  });
}
