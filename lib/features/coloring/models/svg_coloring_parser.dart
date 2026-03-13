import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart' as pp;
import 'package:xml/xml.dart';
import 'coloring_path.dart';

/// SVG 파일 문자열을 파싱하여 [ColoringPath] 목록으로 변환.
class SvgColoringParser {
  static const double _tinyAreaThreshold = 400.0; // 20×20 px²

  /// [svgString]에서 모든 path 요소를 파싱하여 반환.
  static List<ColoringPath> parse(String svgString) {
    final document = XmlDocument.parse(svgString);
    final pathElements = document.findAllElements('path');
    final result = <ColoringPath>[];

    int index = 0;
    for (final element in pathElements) {
      final d = element.getAttribute('d');
      final fillAttr = element.getAttribute('fill');
      final fillRule = element.getAttribute('fill-rule');
      if (d == null || d.isEmpty) {
        index++;
        continue;
      }

      final color = _parseColor(fillAttr);
      final path = _parsePath(d, fillRule);

      final bounds = path.getBounds();
      final effectivePath = bounds.isEmpty ? (ui.Path()..addRect(Rect.zero)) : path;
      final effectiveBounds = effectivePath.getBounds();

      final area = effectiveBounds.width * effectiveBounds.height;
      final isTiny = area < _tinyAreaThreshold;
      final isWhite = color != null && _isNearWhite(color);

      result.add(ColoringPath(
        index: index,
        path: effectivePath,
        fillColor: color ?? const Color(0xFF2EA3AE),
        bounds: effectiveBounds,
        isTiny: isTiny,
        isWhite: isWhite,
      ));
      index++;
    }
    return result;
  }

  static ui.Path _parsePath(String d, String? fillRule) {
    final path = ui.Path();
    if (fillRule == 'evenodd') {
      path.fillType = ui.PathFillType.evenOdd;
    }
    try {
      pp.writeSvgPathDataToPath(d, _FlutterPathProxy(path));
    } catch (_) {
      // 파싱 실패: 빈 path 반환 (호출부에서 fallback 처리)
    }
    return path;
  }

  /// #RRGGBB 형식의 색상 문자열을 [Color]로 변환.
  static Color? _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return null;
    final hex = colorStr.replaceFirst('#', '');
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return null;
  }

  static bool _isNearWhite(Color color) {
    return color.r > 0.99 && color.g > 0.99 && color.b > 0.99;
  }
}

/// [ui.Path]를 path_parsing의 PathProxy 인터페이스에 연결하는 어댑터.
class _FlutterPathProxy extends pp.PathProxy {
  final ui.Path path;
  _FlutterPathProxy(this.path);

  @override
  void close() => path.close();

  @override
  void cubicTo(
    double x1, double y1,
    double x2, double y2,
    double x3, double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}
