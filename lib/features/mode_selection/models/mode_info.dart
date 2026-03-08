import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_mode.dart';

/// 각 그리기 모드의 메타데이터를 담는 불변 데이터 클래스.
/// 새로운 모드 추가 시 [registry] 리스트에만 항목을 추가하면 됨 (레지스트리 패턴).
class ModeInfo {
  final DrawingMode mode;
  final String title;
  final String description;
  final IconData icon;
  final Color cardColor;

  /// 카드 썸네일 이미지 경로. null이면 그라디언트+아이콘 플레이스홀더로 표시.
  final String? imagePath;

  /// AppColors.modeCardGradients 인덱스 (이미지 없을 때 사용).
  final int gradientIndex;

  const ModeInfo({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.cardColor,
    this.imagePath,
    this.gradientIndex = 0,
  });

  /// 앱에 등록된 모든 그리기 모드 목록.
  /// 순서가 UI 카드 배치 순서가 됨.
  static const List<ModeInfo> registry = [
    ModeInfo(
      mode: DrawingMode.free,
      title: '자유 그리기',
      description: '마음껏 그려요!',
      icon: Icons.brush_rounded,
      cardColor: Color(0xFFFF8A80),
      gradientIndex: 0,
    ),
    ModeInfo(
      mode: DrawingMode.trace,
      title: '선 따라 그리기',
      description: '선을 따라 그려요!',
      icon: Icons.gesture,
      cardColor: Color(0xFF82B1FF),
      gradientIndex: 1,
    ),
    ModeInfo(
      mode: DrawingMode.colorBySymbol,
      title: '숫자/ABC 색칠',
      description: '숫자대로 색칠해요!',
      icon: Icons.format_color_fill_rounded,
      cardColor: Color(0xFF69F0AE),
      gradientIndex: 2,
    ),
    ModeInfo(
      mode: DrawingMode.symmetry,
      title: '대칭 그리기',
      description: '똑같이 그려져요!',
      icon: Icons.flip_rounded,
      cardColor: Color(0xFFFFD740),
      gradientIndex: 3,
    ),
  ];
}
