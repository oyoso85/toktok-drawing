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

  const ModeInfo({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.cardColor,
  });

  /// 앱에 등록된 모든 그리기 모드 목록.
  /// 순서가 UI 카드 배치 순서가 됨.
  static const List<ModeInfo> registry = [
    ModeInfo(
      mode: DrawingMode.free,
      title: '자유 그리기',
      description: '마음껏 그려요!',
      icon: Icons.brush_rounded,
      cardColor: Color(0xFFFFB3B3),
    ),
    ModeInfo(
      mode: DrawingMode.trace,
      title: '선 따라 그리기',
      description: '선을 따라 그려요!',
      icon: Icons.gesture,
      cardColor: Color(0xFFB3D9FF),
    ),
    ModeInfo(
      mode: DrawingMode.colorBySymbol,
      title: '숫자/ABC 색칠',
      description: '숫자대로 색칠해요!',
      icon: Icons.format_color_fill_rounded,
      cardColor: Color(0xFFB3FFB3),
    ),
    ModeInfo(
      mode: DrawingMode.symmetry,
      title: '대칭 그리기',
      description: '똑같이 그려져요!',
      icon: Icons.flip_rounded,
      cardColor: Color(0xFFFFE0B3),
    ),
  ];
}
