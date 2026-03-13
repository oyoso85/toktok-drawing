import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 채우기 애니메이션의 공통 인터페이스.
/// [t] 는 0.0 → 1.0 범위의 애니메이션 진행도.
/// 구현체는 반드시 [canvas.clipPath(targetPath)]를 호출하여 경계를 준수해야 한다.
abstract class FillAnimationPainter {
  const FillAnimationPainter();

  /// 채우기 효과를 캔버스에 그린다.
  /// [targetPath] SVG 좌표계 기준 경로 (캔버스 변환은 호출부에서 처리).
  /// [tapOffset] SVG 좌표계 기준 탭 위치 (일부 효과에서 시작점으로 사용).
  void paint(
    Canvas canvas,
    Size size,
    ui.Path targetPath,
    Color fillColor,
    double t,
    Offset tapOffset,
  );

  /// 이 효과의 총 애니메이션 지속 시간.
  Duration get duration;
}
