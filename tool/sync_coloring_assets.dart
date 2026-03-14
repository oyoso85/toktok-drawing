/// 색칠하기 SVG 에셋 동기화 스크립트
///
/// assets/templates/coloring/ 하위 폴더를 스캔하여
/// pubspec.yaml과 svg_template_registry.dart를 자동으로 업데이트한다.
///
/// 사용법:
///   dart run tool/sync_coloring_assets.dart
///
/// SVG 추가 방법:
///   1. assets/templates/coloring/{폴더명}/ 생성
///   2. SVG 파일 넣기 (파일명은 폴더명과 동일하게: {폴더명}.svg)
///   3. (선택) name.txt 파일에 화면에 표시할 이름 작성 (없으면 폴더명 사용)
///   4. dart run tool/sync_coloring_assets.dart 실행

import 'dart:io';

const _coloringAssetsDir = 'assets/templates/coloring';
const _pubspecPath = 'pubspec.yaml';
const _registryPath = 'lib/features/coloring/data/svg_template_registry.dart';

void main() {
  // 1. 폴더 스캔
  final templates = _scanTemplates();

  if (templates.isEmpty) {
    print('템플릿 없음: $_coloringAssetsDir 하위에 SVG 폴더가 없습니다.');
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

  final subDirs = dir.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final subDir in subDirs) {
    final id = subDir.uri.pathSegments.lastWhere((s) => s.isNotEmpty);

    // {폴더명}.svg 파일 탐색
    final svgFile = File('${subDir.path}/$id.svg');
    if (!svgFile.existsSync()) {
      // 폴더 내 첫 번째 SVG로 폴백
      final anySvg = subDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'))
          .toList();
      if (anySvg.isEmpty) continue;  // SVG 없는 폴더 무시
    }

    // name.txt에서 표시 이름 읽기 (없으면 폴더명 사용)
    final nameFile = File('${subDir.path}/name.txt');
    final name = nameFile.existsSync()
        ? nameFile.readAsStringSync().trim()
        : id;

    final svgPath = svgFile.existsSync()
        ? '$_coloringAssetsDir/$id/$id.svg'
        : _firstSvgPath(subDir);

    templates.add(_Template(id: id, name: name, assetPath: svgPath));
  }

  return templates;
}

String _firstSvgPath(Directory dir) {
  final file = dir
      .listSync()
      .whereType<File>()
      .firstWhere((f) => f.path.endsWith('.svg'));
  final fileName = file.uri.pathSegments.last;
  final id = dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
  return '$_coloringAssetsDir/$id/$fileName';
}

// ── pubspec.yaml 업데이트 ────────────────────────────────────────────────────

void _updatePubspec(List<_Template> templates) {
  final file = File(_pubspecPath);
  final lines = file.readAsLinesSync();

  // 새로 추가할 경로 목록
  final newFolders = templates
      .map((t) => '    - ${t.assetPath.substring(0, t.assetPath.lastIndexOf('/') + 1)}')
      .toSet();

  // assets: 블록에서 coloring 폴더 항목만 교체
  final result = <String>[];
  var inAssets = false;
  var coloringStart = -1;
  var coloringEnd = -1;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('assets:')) inAssets = true;
    if (inAssets && line.contains('coloring/')) {
      if (coloringStart == -1) coloringStart = i;
      coloringEnd = i;
    }
  }

  if (coloringStart == -1) {
    // coloring 항목이 아예 없으면 assets: 블록 끝에 추가
    stderr.writeln('경고: pubspec.yaml에 coloring 항목이 없습니다. 수동으로 추가하세요.');
    return;
  }

  // coloringStart~coloringEnd 범위를 새 목록으로 교체
  var replaced = false;
  for (var i = 0; i < lines.length; i++) {
    if (i == coloringStart && !replaced) {
      result.addAll(newFolders);
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
