import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart' as pp;
import 'package:xml/xml.dart';
import '../models/trace_template.dart';

/// SVG 파일 기반 선 따라 그리기 도안 레지스트리.
///
/// 도안 추가:
///   1. assets/templates/trace/{id}.svg 추가 (컬러 일러스트 — 썸네일/완성 화면용)
///   2. assets/templates/trace/{id}-trace.svg 추가 (외곽선 전용 — 히트존 경로용)
///   3. assets/templates/trace/{id}-name.txt 추가 (한글 이름)
///   4. 아래 _entries 에 (id, color) 등록
///
/// -trace.svg 가 없으면 {id}.svg 에서 fill="none" path 를 fallback으로 사용.
class TraceTemplateRegistry {
  TraceTemplateRegistry._();

  // 등록된 도안 목록 — id는 파일명과 동일
  static const _entries = [
    (id: 'line-alligator', color: Color(0xFF5E991A)),
    (id: 'line-deer',      color: Color(0xFF7A3C0E)),
    (id: 'line-elephant',  color: Color(0xFF6A9CCE)),
    (id: 'line-monkey',    color: Color(0xFFA95439)),
    (id: 'line-tiger',     color: Color(0xFFFF7300)),
  ];

  static List<TraceTemplate>? _cache;

  /// 전체 템플릿 비동기 로드 (캐시됨).
  static Future<List<TraceTemplate>> loadAll() async {
    if (_cache != null) return _cache!;
    final result = <TraceTemplate>[];
    for (final e in _entries) {
      final tmpl = await _load(e.id, e.color);
      if (tmpl != null) result.add(tmpl);
    }
    _cache = result;
    return result;
  }

  /// 캐시 무효화 (테스트/핫리로드용).
  static void invalidateCache() => _cache = null;

  // ── 개별 템플릿 로드 ──────────────────────────────────────────────────────

  static Future<TraceTemplate?> _load(String id, Color color) async {
    try {
      final svgPath      = 'assets/templates/trace/$id.svg';
      final traceSvgPath = 'assets/templates/trace/$id-trace.svg';
      final namePath     = 'assets/templates/trace/$id-name.txt';

      final name = (await rootBundle.loadString(namePath)).trim();

      // -trace.svg 우선 사용 (외곽선 전용), 없으면 메인 SVG fallback
      String traceSvg;
      try {
        traceSvg = await rootBundle.loadString(traceSvgPath);
      } catch (_) {
        traceSvg = await rootBundle.loadString(svgPath);
      }

      final parsedPath = _parseOutlinePaths(traceSvg);
      if (parsedPath == null) return null;

      // viewBox를 기준으로 path 배치 — color SVG(flutter_svg)와 동일한 좌표계
      final viewBox = _parseViewBox(traceSvg) ?? parsedPath.getBounds();
      if (viewBox.isEmpty) return null;

      return TraceTemplate(
        id: id,
        name: name.isEmpty ? id : name,
        thumbnailColor: color,
        svgAsset: svgPath,
        pathBuilder: (size) => _fitPath(parsedPath, viewBox, size),
        completionRect: (size) => _computeFitRect(viewBox, size),
      );
    } catch (e) {
      debugPrint('TraceTemplateRegistry: $id 로드 실패 — $e');
      return null;
    }
  }

  // ── viewBox 파싱 ──────────────────────────────────────────────────────────

  /// SVG viewBox 속성을 Rect로 파싱.
  static Rect? _parseViewBox(String svgString) {
    try {
      final doc  = XmlDocument.parse(svgString);
      final svgEl = doc.findAllElements('svg').first;
      final vb   = svgEl.getAttribute('viewBox');
      if (vb == null) return null;
      final parts = vb.trim().split(RegExp(r'[\s,]+'));
      if (parts.length < 4) return null;
      return Rect.fromLTWH(
        double.parse(parts[0]),
        double.parse(parts[1]),
        double.parse(parts[2]),
        double.parse(parts[3]),
      );
    } catch (_) {
      return null;
    }
  }

  // ── SVG 파싱 ─────────────────────────────────────────────────────────────

  /// SVG에서 outline path (fill="none" stroke=...)를 우선 추출.
  /// outline이 없으면 전체 path를 합산.
  static ui.Path? _parseOutlinePaths(String svgString) {
    final document = XmlDocument.parse(svgString);
    final allPaths = document.findAllElements('path').toList();
    if (allPaths.isEmpty) return null;

    // 1차: fill="none" 인 outline path 만 추출
    final outlineElements = allPaths
        .where((e) => _resolveFill(e) == 'none')
        .toList();

    final elements = outlineElements.isNotEmpty ? outlineElements : allPaths;

    final combined = ui.Path();
    for (final el in elements) {
      final d = el.getAttribute('d');
      if (d == null || d.isEmpty) continue;
      try {
        final p = ui.Path();
        pp.writeSvgPathDataToPath(d, _PathProxy(p));
        combined.addPath(p, Offset.zero);
      } catch (_) {}
    }

    final bounds = combined.getBounds();
    return bounds.isEmpty ? null : combined;
  }

  static String? _resolveFill(XmlElement el) {
    final fill = el.getAttribute('fill');
    if (fill != null) return fill.toLowerCase().trim();
    final style = el.getAttribute('style') ?? '';
    final m = RegExp(r'fill\s*:\s*([^;]+)').firstMatch(style);
    return m?.group(1)?.toLowerCase().trim();
  }

  // ── 캔버스 fit ────────────────────────────────────────────────────────────

  /// viewBox 기준으로 aspect-fit + 10% 패딩 Rect 계산.
  /// _fitPath 와 동일한 수식 — 두 결과가 완전히 일치한다.
  static Rect _computeFitRect(Rect bounds, Size canvasSize) {
    const paddingRatio = 0.10;
    final padX   = canvasSize.width  * paddingRatio;
    final padY   = canvasSize.height * paddingRatio;
    final availW = canvasSize.width  - padX * 2;
    final availH = canvasSize.height - padY * 2;

    final scaleX = availW / bounds.width;
    final scaleY = availH / bounds.height;
    final scale  = scaleX < scaleY ? scaleX : scaleY;

    final scaledW = bounds.width  * scale;
    final scaledH = bounds.height * scale;
    final left    = padX + (availW - scaledW) / 2;
    final top     = padY + (availH - scaledH) / 2;

    return Rect.fromLTWH(left, top, scaledW, scaledH);
  }

  /// 원본 Path를 캔버스 크기에 aspect-fit + 10% 패딩으로 변환 (viewBox 기준).
  static ui.Path _fitPath(ui.Path src, Rect bounds, Size canvasSize) {
    final rect  = _computeFitRect(bounds, canvasSize);
    final scale = rect.width / bounds.width;
    final tx    = rect.left - bounds.left * scale;
    final ty    = rect.top  - bounds.top  * scale;

    // column-major 4×4: scale on diagonal, translate in last column
    final m = Float64List(16);
    m[0]  = scale; m[5]  = scale; m[10] = 1.0; m[15] = 1.0;
    m[12] = tx;    m[13] = ty;
    return src.transform(m);
  }
}

// ── PathProxy 어댑터 ──────────────────────────────────────────────────────────

class _PathProxy extends pp.PathProxy {
  final ui.Path path;
  _PathProxy(this.path);

  @override void close() => path.close();
  @override void moveTo(double x, double y) => path.moveTo(x, y);
  @override void lineTo(double x, double y) => path.lineTo(x, y);
  @override void cubicTo(
    double x1, double y1, double x2, double y2, double x3, double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);
}
