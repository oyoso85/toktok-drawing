import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';

/// 각 도구의 고유 컬러 정의.
/// [bg]: 미선택 시 연한 배경
/// [active]: 선택 시 풀 채도 배경
/// [glow]: boxShadow glow 색상
class ToolColorSet {
  final Color bg;
  final Color active;
  final Color glow;
  /// null이면 단색, non-null이면 그라디언트
  final Gradient? gradient;

  const ToolColorSet({
    required this.bg,
    required this.active,
    required this.glow,
    this.gradient,
  });
}

class ToolColors {
  static const Map<DrawingTool, ToolColorSet> colors = {
    DrawingTool.pen: ToolColorSet(
      bg: Color(0xFFE3F2FD),
      active: Color(0xFF4FC3F7),
      glow: Color(0x994FC3F7),
    ),
    DrawingTool.brush: ToolColorSet(
      bg: Color(0xFFE8F5E9),
      active: Color(0xFF81C784),
      glow: Color(0x9981C784),
    ),
    DrawingTool.pencil: ToolColorSet(
      bg: Color(0xFFFFF3E0),
      active: Color(0xFFFFB74D),
      glow: Color(0x99FFB74D),
    ),
    DrawingTool.dryPencil: ToolColorSet(
      bg: Color(0xFFF0EBE3),
      active: Color(0xFF8D6E63),
      glow: Color(0x998D6E63),
    ),
    DrawingTool.watercolorPencil: ToolColorSet(
      bg: Color(0xFFE0F7FA),
      active: Color(0xFF26C6DA),
      glow: Color(0x9926C6DA),
    ),
    DrawingTool.eraser: ToolColorSet(
      bg: Color(0xFFF3E5F5),
      active: Color(0xFFCE93D8),
      glow: Color(0x99CE93D8),
    ),
    DrawingTool.rainbowBrush: ToolColorSet(
      bg: Color(0xFFFCE4EC),
      active: Color(0xFFFF80AB),
      glow: Color(0x99FF80AB),
    ),
    DrawingTool.sparkleBrush: ToolColorSet(
      bg: Color(0xFFFFF8E1),
      active: Color(0xFFFFD54F),
      glow: Color(0x99FFD54F),
    ),
  };

  /// rainbow gradient (무지개붓 선택 시 배경)
  static const rainbowGradient = LinearGradient(
    colors: [
      Color(0xFFFF5252),
      Color(0xFFFF9800),
      Color(0xFFFFEB3B),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFF9C27B0),
    ],
  );

  static ToolColorSet of(DrawingTool tool) =>
      colors[tool] ?? colors[DrawingTool.pen]!;
}
