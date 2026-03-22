import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart' as pp;
import 'package:xml/xml.dart';
import 'coloring_path.dart';

/// SVG 파일 문자열을 파싱하여 [ColoringPath] 목록으로 변환.
///
/// Illustrator export 설정에 따른 다양한 형식을 자동 처리:
///   - Presentation Attributes : fill="#e6a032"          (권장)
///   - Inline Style            : style="fill:#e6a032"
///   - Internal CSS            : <style>.cls-1{fill:#e6a032}</style>
///   - rgb() 색상              : fill="rgb(230,160,50)"
class SvgColoringParser {
  /// SVG 루트 요소의 viewBox 크기를 반환.
  /// viewBox 속성이 없으면 width/height 속성을 사용하고, 그것도 없으면 (630, 648) 기본값 반환.
  static Size parseViewBox(String svgString) {
    final document = XmlDocument.parse(svgString);
    final svg = document.findElements('svg').firstOrNull;
    if (svg == null) return const Size(630, 648);

    final viewBox = svg.getAttribute('viewBox');
    if (viewBox != null) {
      final parts = viewBox.trim().split(RegExp(r'[\s,]+'));
      if (parts.length == 4) {
        final w = double.tryParse(parts[2]);
        final h = double.tryParse(parts[3]);
        if (w != null && h != null && w > 0 && h > 0) return Size(w, h);
      }
    }

    final w = double.tryParse(
        (svg.getAttribute('width') ?? '').replaceAll(RegExp(r'[^\d.]'), ''));
    final h = double.tryParse(
        (svg.getAttribute('height') ?? '').replaceAll(RegExp(r'[^\d.]'), ''));
    if (w != null && h != null && w > 0 && h > 0) return Size(w, h);

    return const Size(630, 648);
  }
  static const double _tinyAreaThreshold = 400.0;  // 면적 기준: 20×20 px²

  /// [svgString]에서 모든 path 요소를 파싱하여 반환.
  static List<ColoringPath> parse(String svgString) {
    final document = XmlDocument.parse(svgString);

    // <style> 블록의 CSS 클래스 → 색상 맵 추출
    final cssClassColors = _parseCssClassColors(document);

    final pathElements = document.findAllElements('path');
    final result = <ColoringPath>[];
    final seenDStrings = <String>{};  // Illustrator 중복 path 제거용

    // <g> 요소 → 그룹 ID 맵 (파싱 중 생성)
    final gElementIds = <XmlElement, String>{};
    int gCounter = 0;

    int index = 0;
    for (final element in pathElements) {
      final d = element.getAttribute('d');
      if (d == null || d.isEmpty) {
        index++;
        continue;
      }

      // 동일한 d 속성을 가진 중복 path 제거 (Illustrator export 아티팩트)
      if (!seenDStrings.add(d)) {
        index++;
        continue;
      }

      final fillRule = _resolveFillRule(element);
      final color = _resolveFillColor(element, cssClassColors);
      final path = _parsePath(d, fillRule);

      final bounds = path.getBounds();
      final effectivePath = bounds.isEmpty ? (ui.Path()..addRect(Rect.zero)) : path;
      final effectiveBounds = effectivePath.getBounds();

      final area = effectiveBounds.width * effectiveBounds.height;
      final isTiny = area < _tinyAreaThreshold;
      final isWhite = color != null && _isNearWhite(color);
      final isBlack = color != null && _isNearBlack(color);

      // 가장 가까운 부모 <g> 찾기
      final groupId = _resolveGroupId(element, gElementIds, () {
        gCounter++;
        return 'g$gCounter';
      });

      result.add(ColoringPath(
        index: index,
        path: effectivePath,
        fillColor: color ?? const Color(0xFF2EA3AE),
        bounds: effectiveBounds,
        isTiny: isTiny,
        isWhite: isWhite,
        isBlack: isBlack,
        groupId: groupId,
      ));
      index++;
    }
    return result;
  }

  // ── fill 색상 해석 ──────────────────────────────────────────────────────────

  /// 우선순위: style 속성 > fill 속성 > class 속성(CSS) > 부모 상속(미지원, null 반환)
  static Color? _resolveFillColor(
    XmlElement element,
    Map<String, Color> cssClassColors,
  ) {
    // 1) style="...fill:#rrggbb..." 또는 style="...fill:rgb(r,g,b)..."
    final styleAttr = element.getAttribute('style');
    if (styleAttr != null) {
      final fromStyle = _parseFillFromStyle(styleAttr);
      if (fromStyle != null) return fromStyle;
    }

    // 2) fill="#rrggbb" 또는 fill="rgb(r,g,b)"
    final fillAttr = element.getAttribute('fill');
    if (fillAttr != null && fillAttr.isNotEmpty && fillAttr != 'none') {
      final fromAttr = _parseColorString(fillAttr);
      if (fromAttr != null) return fromAttr;
    }

    // 3) class="cls-1 cls-2 ..." → CSS 클래스에서 fill 탐색
    final classAttr = element.getAttribute('class');
    if (classAttr != null) {
      for (final cls in classAttr.trim().split(RegExp(r'\s+'))) {
        final fromCss = cssClassColors[cls];
        if (fromCss != null) return fromCss;
      }
    }

    return null;
  }

  /// fill-rule: style 속성 우선, 없으면 fill-rule 속성
  static String? _resolveFillRule(XmlElement element) {
    final styleAttr = element.getAttribute('style');
    if (styleAttr != null) {
      final match = RegExp(r'fill-rule\s*:\s*(evenodd|nonzero)').firstMatch(styleAttr);
      if (match != null) return match.group(1);
    }
    return element.getAttribute('fill-rule');
  }

  // ── CSS 파싱 ───────────────────────────────────────────────────────────────

  /// SVG <style> 블록에서 `.className { fill: #rrggbb }` 형태 추출.
  static Map<String, Color> _parseCssClassColors(XmlDocument document) {
    final result = <String, Color>{};
    for (final styleEl in document.findAllElements('style')) {
      final css = styleEl.innerText;
      // .cls-1{fill:#e6a032} 또는 .cls-1 { fill: rgb(230,160,50) }
      final classBlocks = RegExp(r'\.([\w-]+)\s*\{([^}]*)\}').allMatches(css);
      for (final block in classBlocks) {
        final className = block.group(1)!;
        final body = block.group(2)!;
        final fillMatch = RegExp(r'fill\s*:\s*([^;]+)').firstMatch(body);
        if (fillMatch != null) {
          final color = _parseColorString(fillMatch.group(1)!.trim());
          if (color != null) result[className] = color;
        }
      }
    }
    return result;
  }

  // ── 색상 문자열 파싱 ────────────────────────────────────────────────────────

  /// style 속성 문자열에서 fill 값 추출 후 Color로 변환.
  static Color? _parseFillFromStyle(String style) {
    final match = RegExp(r'(?:^|;)\s*fill\s*:\s*([^;]+)').firstMatch(style);
    if (match == null) return null;
    return _parseColorString(match.group(1)!.trim());
  }

  /// `#RRGGBB`, `#RGB`, `rgb(r,g,b)` 형식을 [Color]로 변환.
  static Color? _parseColorString(String colorStr) {
    final s = colorStr.trim().toLowerCase();

    // #RRGGBB
    if (s.startsWith('#')) {
      final hex = s.substring(1);
      if (hex.length == 6) {
        final value = int.tryParse(hex, radix: 16);
        if (value != null) return Color(0xFF000000 | value);
      }
      // #RGB → #RRGGBB
      if (hex.length == 3) {
        final expanded = hex.split('').map((c) => '$c$c').join();
        final value = int.tryParse(expanded, radix: 16);
        if (value != null) return Color(0xFF000000 | value);
      }
    }

    // rgb(r, g, b)
    final rgbMatch = RegExp(r'rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)').firstMatch(s);
    if (rgbMatch != null) {
      final r = int.tryParse(rgbMatch.group(1)!) ?? 0;
      final g = int.tryParse(rgbMatch.group(2)!) ?? 0;
      final b = int.tryParse(rgbMatch.group(3)!) ?? 0;
      return Color.fromARGB(255, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
    }

    return null;
  }

  /// 가장 가까운 부모 <g> 요소의 그룹 ID를 반환.
  /// <g>에 id 속성이 있으면 그것을 사용, 없으면 [generateId]로 생성.
  /// 부모 <g>가 없으면 null 반환.
  static String? _resolveGroupId(
    XmlElement element,
    Map<XmlElement, String> cache,
    String Function() generateId,
  ) {
    XmlNode? node = element.parent;
    while (node != null) {
      if (node is XmlElement && node.localName == 'g') {
        return cache.putIfAbsent(node, () {
          return node!.getAttribute('id') ?? generateId();
        });
      }
      node = node.parent;
    }
    return null;
  }

  static bool _isNearWhite(Color color) {
    return color.r > 0.99 && color.g > 0.99 && color.b > 0.99;
  }

  static bool _isNearBlack(Color color) {
    return color.r < 0.15 && color.g < 0.15 && color.b < 0.15;
  }

  // ── Path 파싱 ──────────────────────────────────────────────────────────────

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
