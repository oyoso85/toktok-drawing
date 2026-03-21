/// 색칠하기 SVG 에셋 동기화 스크립트
///
/// assets/templates/coloring/ 하위 SVG 파일을 스캔하여
/// pubspec.yaml과 svg_template_registry.dart를 자동으로 업데이트한다.
///
/// 사용법:
///   dart run tool/sync_coloring_assets.dart
///
/// SVG 추가 방법:
///   1. assets/templates/coloring/{id}.svg 파일 추가
///   2. (선택) assets/templates/coloring/{id}-name.txt 에 표시할 이름 작성 (없으면 id 사용)
///   3. dart run tool/sync_coloring_assets.dart 실행

import 'dart:io';

const _coloringAssetsDir = 'assets/templates/coloring';
const _pubspecPath = 'pubspec.yaml';
const _registryPath = 'lib/features/coloring/data/svg_template_registry.dart';

void main() {
  // 1. SVG 파일 스캔
  final templates = _scanTemplates();

  if (templates.isEmpty) {
    print('템플릿 없음: $_coloringAssetsDir 하위에 SVG 파일이 없습니다.');
    return;
  }

  print('발견된 템플릿 ${templates.length}개:');
  for (final t in templates) {
    print('  ${t.id} → "${t.name}" (${t.assetPath})');
  }

  // 2. pubspec.yaml 업데이트
  _updatePubspec(templates);

  // 3. svg_template_registry.dart 재생성
  _updateRegistry(templates);

  print('\n완료!');
}

// ── 템플릿 스캔 ──────────────────────────────────────────────────────────────

class _Template {
  final String id;
  final String name;
  final String assetPath;
  const _Template({required this.id, required this.name, required this.assetPath});
}

List<_Template> _scanTemplates() {
  final dir = Directory(_coloringAssetsDir);
  if (!dir.existsSync()) {
    stderr.writeln('오류: $_coloringAssetsDir 폴더를 찾을 수 없습니다.');
    exit(1);
  }

  final templates = <_Template>[];

  // 직속 SVG 파일만 스캔 (-name.txt와 쌍을 이루지 않아도 됨)
  final svgFiles = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg') && !f.path.endsWith('.bak'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final svgFile in svgFiles) {
    final fileName = svgFile.uri.pathSegments.last; // e.g. character.svg
    final id = fileName.substring(0, fileName.length - 4); // remove .svg

    // {id}-name.txt 에서 표시 이름 읽기 (없으면 id 사용)
    final nameFile = File('$_coloringAssetsDir/$id-name.txt');
    final name = nameFile.existsSync() ? nameFile.readAsStringSync().trim() : id;

    templates.add(_Template(
      id: id,
      name: name,
      assetPath: '$_coloringAssetsDir/$fileName',
    ));
  }

  return templates;
}

// ── pubspec.yaml 업데이트 ────────────────────────────────────────────────────

void _updatePubspec(List<_Template> templates) {
  final file = File(_pubspecPath);
  final lines = file.readAsLinesSync();

  // coloring 폴더 전체를 단일 항목으로 등록
  const newEntry = '    - $_coloringAssetsDir/';

  // assets: 블록에서 coloring 항목만 교체
  var coloringStart = -1;
  var coloringEnd = -1;

  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('coloring/')) {
      if (coloringStart == -1) coloringStart = i;
      coloringEnd = i;
    }
  }

  if (coloringStart == -1) {
    stderr.writeln('경고: pubspec.yaml에 coloring 항목이 없습니다. 수동으로 추가하세요.');
    return;
  }

  final result = <String>[];
  var replaced = false;
  for (var i = 0; i < lines.length; i++) {
    if (i == coloringStart && !replaced) {
      result.add(newEntry);
      replaced = true;
    }
    if (i >= coloringStart && i <= coloringEnd) continue;
    result.add(lines[i]);
  }

  file.writeAsStringSync(result.join('\n') + '\n');
  print('\npubspec.yaml 업데이트 완료');
}

// ── svg_template_registry.dart 재생성 ───────────────────────────────────────

void _updateRegistry(List<_Template> templates) {
  final entries = templates.map((t) => '''  SvgTemplate(
    id: '${t.id}',
    name: '${t.name}',
    assetPath: '${t.assetPath}',
  ),''').join('\n');

  final content = '''import 'package:toktok_drawing/features/coloring/models/svg_template.dart';

/// 색칠하기 모드에서 표시할 SVG 템플릿 목록.
/// 이 파일은 tool/sync_coloring_assets.dart가 자동 생성합니다.
/// 직접 수정하지 말고 스크립트를 실행하세요.
const List<SvgTemplate> kSvgTemplates = [
$entries
];
''';

  File(_registryPath).writeAsStringSync(content);
  print('svg_template_registry.dart 재생성 완료');
}
