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
/// - 무채색(검정/흰색/회색): 명도 범위만 변하는 회색 계열 반환
/// - 어두운 유채색(갈색 등): 낮은 명도 범위 + 좁은 색상 범위 유사색 반환
/// - 그 외: 선택 색상의 hue를 기준으로 유사색 4~5개 반환
List<Color> generateSparklePalette(Color baseColor) {
  if (baseColor == AppColors.kRainbow) {
    return List.from(rainbowColors);
  }

  final rng = Random();
  final hsl = HSLColor.fromColor(baseColor);

  // 무채색 계열 (채도 < 0.15): 회색 팔레트
  if (hsl.saturation < 0.15) {
    if (hsl.lightness < 0.25) {
      // 검정 → 어두운 회색 (0.08~0.30)
      return List.generate(5, (_) =>
          HSLColor.fromAHSL(1.0, 0, 0, 0.08 + rng.nextDouble() * 0.22).toColor());
    } else if (hsl.lightness > 0.75) {
      // 흰색 → 밝은 회색 (0.70~0.92)
      return List.generate(5, (_) =>
          HSLColor.fromAHSL(1.0, 0, 0, 0.70 + rng.nextDouble() * 0.22).toColor());
    } else {
      // 중간 회색
      return List.generate(5, (_) =>
          HSLColor.fromAHSL(1.0, 0, 0, 0.30 + rng.nextDouble() * 0.35).toColor());
    }
  }

  final baseHue = hsl.hue;
  final count = 4 + rng.nextInt(2); // 4 또는 5개
  final isDark = hsl.lightness < 0.40; // 갈색 등 어두운 유채색

  return List.generate(count, (i) {
    // 어두운 색은 ±20° 좁은 범위, 밝은 색은 ±40° 넓은 범위
    final spread = isDark ? 40.0 : 80.0;
    final offset = (i / (count - 1)) * spread - spread / 2;
    final hue = (baseHue + offset + 360) % 360;

    final saturation = isDark
        ? 0.55 + rng.nextDouble() * 0.20  // 0.55~0.75 (갈색 계열 채도)
        : 0.75 + rng.nextDouble() * 0.17; // 0.75~0.92 (일반)
    final lightness = isDark
        ? 0.22 + rng.nextDouble() * 0.18  // 0.22~0.40 (갈색 계열 명도)
        : 0.48 + rng.nextDouble() * 0.17; // 0.48~0.65 (일반)

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  });
}
