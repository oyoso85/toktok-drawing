import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 도안별 색칠 진행 상태(완성 여부 + 채워진 색상)를 로컬에 저장/로드.
/// 키: SVG 에셋 경로 (예: assets/templates/coloring/character/character.svg)
/// 저장 형식: JSON 파일 (coloring_progress/{encoded_key}.json)
class ColoringProgressService {
  static ColoringProgressService? _instance;
  static ColoringProgressService get instance =>
      _instance ??= ColoringProgressService._();
  ColoringProgressService._();

  Future<Directory> get _dir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'coloring_progress'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _fileName(String assetPath) {
    // 경로를 파일명으로 변환: 슬래시/점 → 언더스코어
    return '${assetPath.replaceAll(RegExp(r'[/.]'), '_')}.json';
  }

  /// 완성된 색칠 상태 저장. [filledPaths]: index → color 정수값
  Future<void> saveCompleted(
    String assetPath,
    Map<int, Color> filledPaths,
  ) async {
    final dir = await _dir;
    final file = File(p.join(dir.path, _fileName(assetPath)));
    final data = {
      'isCompleted': true,
      'filledPaths': filledPaths
          .map((k, v) => MapEntry(k.toString(), v.toARGB32())),
    };
    await file.writeAsString(jsonEncode(data));
  }

  /// 저장된 색칠 상태 로드. 없거나 미완성이면 null 반환.
  Future<Map<int, Color>?> loadCompleted(String assetPath) async {
    final dir = await _dir;
    final file = File(p.join(dir.path, _fileName(assetPath)));
    if (!await file.exists()) return null;

    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (data['isCompleted'] != true) return null;
      final raw = data['filledPaths'] as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(int.parse(k), Color(v as int)));
    } catch (_) {
      return null;
    }
  }

  /// 완성 여부만 확인 (썸네일 배지 표시 등에 활용).
  Future<bool> isCompleted(String assetPath) async {
    final result = await loadCompleted(assetPath);
    return result != null;
  }
}
