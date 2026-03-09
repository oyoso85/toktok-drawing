import 'dart:math';
import 'package:flutter/material.dart' show HSLColor, Color;

/// 꽃씨 붓용 팔레트 생성.
/// 선택 색상의 hue를 기준으로 ±40° 범위의 유사색(analogous) 4~5개를 반환.
/// saturation(0.75~0.92)과 lightness(0.48~0.65)에 약간의 변화를 줘서
/// 생동감 있는 계열 색상을 만든다.
List<Color> generateSparklePalette(Color baseColor) {
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
