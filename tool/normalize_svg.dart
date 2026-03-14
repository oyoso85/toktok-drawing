/// SVG 정규화 스크립트
///
/// Illustrator의 다양한 export 설정으로 저장된 SVG를 앱 파서 친화적인
/// 형식(Presentation Attributes + #RRGGBB)으로 변환한다.
///
/// 사용법:
///   dart run tool/normalize_svg.dart [파일 또는 폴더 경로]
///
/// 예시:
///   dart run tool/normalize_svg.dart assets/templates/coloring/character/character.svg
///   dart run tool/normalize_svg.dart assets/templates/coloring/
///
/// 처리 내용:
///   1. style="fill:#rrggbb" → fill="#rrggbb" (Presentation Attributes 변환)
///   2. fill="rgb(r,g,b)"   → fill="#rrggbb" (rgb → hex 변환)
///   3. <style> CSS 클래스  → 각 path에 fill 속성 직접 부여 후 <style> 제거
///   4. 동일한 d 속성을 가진 중복 path 제거
///   5. 원본 파일 덮어쓰기 (백업: 같은 위치에 .bak 파일 생성)

import 'dart:io';
import 'package:xml/xml.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('사용법: dart run tool/normalize_svg.dart <파일 또는 폴더>');
    exit(1);
  }

  final target = FileSystemEntity.typeSync(args[0]);
  if (target == FileSystemEntityType.file) {
    _processFile(File(args[0]));
  } else if (target == FileSystemEntityType.directory) {
    final svgFiles = Directory(args[0])
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'));
    for (final file in svgFiles) {
      _processFile(file);
    }
  } else {
    stderr.writeln('오류: 파일 또는 폴더를 찾을 수 없습니다: ${args[0]}');
    exit(1);
  }
}

void _processFile(File file) {
  print('처리 중: ${file.path}');
  final original = file.readAsStringSync();

  try {
    final result = normalizeSvg(original);
    if (result == original) {
      print('  → 변경 없음 (이미 올바른 형식)');
      return;
    }
    // 백업 생성
    File('${file.path}.bak').writeAsStringSync(original);
    file.writeAsStringSync(result);
    print('  → 정규화 완료 (백업: ${file.path}.bak)');
  } catch (e) {
    stderr.writeln('  → 오류: $e');
  }
}

/// SVG 문자열을 정규화하여 반환.
String normalizeSvg(String svgString) {
  final document = XmlDocument.parse(svgString);

  // 1. <style> 블록에서 CSS 클래스 → 색상 맵 추출
  final cssClassColors = _parseCssClassColors(document);

  // 2. 각 path 요소 처리
  final seenDStrings = <String>{};
  final pathsToRemove = <XmlElement>[];

  for (final element in document.findAllElements('path').toList()) {
    final d = element.getAttribute('d') ?? '';
    if (d.isEmpty) continue;

    // 중복 path 제거
    if (!seenDStrings.add(d)) {
      pathsToRemove.add(element);
      continue;
    }

    // fill 색상 정규화
    _normalizeFill(element, cssClassColors);

    // fill-rule 정규화
    _normalizeFillRule(element);

    // style 속성에서 처리된 항목 제거 (나머지 style 속성은 유지하되 fill/fill-rule만 제거)
    _cleanStyleAttr(element);
  }

  // 중복 path 제거
  for (final el in pathsToRemove) {
    el.parent?.children.remove(el);
  }

  // 3. <style> 블록 제거 (CSS 클래스가 있었던 경우)
  if (cssClassColors.isNotEmpty) {
    for (final styleEl in document.findAllElements('style').toList()) {
      styleEl.parent?.children.remove(styleEl);
    }
    print('  → CSS 클래스 ${cssClassColors.length}개 → fill 속성으로 변환, <style> 제거');
  }

  if (pathsToRemove.isNotEmpty) {
    print('  → 중복 path ${pathsToRemove.length}개 제거');
  }

  return document.toXmlString(pretty: false);
}

// ── fill 정규화 ──────────────────────────────────────────────────────────────

void _normalizeFill(XmlElement element, Map<String, Color> cssClassColors) {
  Color? color;

  // 우선순위: style > fill 속성 > class
  final styleAttr = element.getAttribute('style') ?? '';
  color ??= _parseFillFromStyle(styleAttr);

  final fillAttr = element.getAttribute('fill') ?? '';
  if (fillAttr.isNotEmpty && fillAttr != 'none') {
    color ??= _parseColorString(fillAttr);
  }

  final classAttr = element.getAttribute('class') ?? '';
  for (final cls in classAttr.trim().split(RegExp(r'\s+'))) {
    color ??= cssClassColors[cls];
  }

  if (color != null) {
    final hex = '#${_toHex(color.r)}${_toHex(color.g)}${_toHex(color.b)}';
    element.setAttribute('fill', hex);
  }
}

void _normalizeFillRule(XmlElement element) {
  final styleAttr = element.getAttribute('style') ?? '';
  final match = RegExp(r'fill-rule\s*:\s*(evenodd|nonzero)').firstMatch(styleAttr);
  if (match != null) {
    element.setAttribute('fill-rule', match.group(1)!);
  }
}

/// style 속성에서 fill, fill-rule 항목만 제거 (나머지는 유지)
void _cleanStyleAttr(XmlElement element) {
  final styleAttr = element.getAttribute('style');
  if (styleAttr == null) return;

  final cleaned = styleAttr
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .where((s) => !s.startsWith('fill'))
      .join('; ');

  if (cleaned.isEmpty) {
    element.removeAttribute('style');
  } else {
    element.setAttribute('style', cleaned);
  }
}

// ── CSS 파싱 ─────────────────────────────────────────────────────────────────

Map<String, Color> _parseCssClassColors(XmlDocument document) {
  final result = <String, Color>{};
  for (final styleEl in document.findAllElements('style')) {
    final css = styleEl.innerText;
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

// ── 색상 파싱 ─────────────────────────────────────────────────────────────────

Color? _parseFillFromStyle(String style) {
  final match = RegExp(r'(?:^|;)\s*fill\s*:\s*([^;]+)').firstMatch(style);
  if (match == null) return null;
  return _parseColorString(match.group(1)!.trim());
}

Color? _parseColorString(String colorStr) {
  final s = colorStr.trim().toLowerCase();
  if (s.startsWith('#')) {
    final hex = s.substring(1);
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) {
        return Color(
          a: 255,
          r: (value >> 16) & 0xFF,
          g: (value >> 8) & 0xFF,
          b: value & 0xFF,
        );
      }
    }
    if (hex.length == 3) {
      final expanded = hex.split('').map((c) => '$c$c').join();
      final value = int.tryParse(expanded, radix: 16);
      if (value != null) {
        return Color(
          a: 255,
          r: (value >> 16) & 0xFF,
          g: (value >> 8) & 0xFF,
          b: value & 0xFF,
        );
      }
    }
  }
  final rgbMatch = RegExp(r'rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)').firstMatch(s);
  if (rgbMatch != null) {
    return Color(
      a: 255,
      r: (int.tryParse(rgbMatch.group(1)!) ?? 0).clamp(0, 255),
      g: (int.tryParse(rgbMatch.group(2)!) ?? 0).clamp(0, 255),
      b: (int.tryParse(rgbMatch.group(3)!) ?? 0).clamp(0, 255),
    );
  }
  return null;
}

String _toHex(int value) => value.toRadixString(16).padLeft(2, '0');

// ── 경량 Color 클래스 (Flutter 미의존) ──────────────────────────────────────

class Color {
  final int a, r, g, b;
  const Color({required this.a, required this.r, required this.g, required this.b});
}
