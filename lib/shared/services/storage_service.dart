import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:toktok_drawing/shared/models/drawing_data.dart';
import 'package:toktok_drawing/shared/models/drawing_mode.dart';

class DrawingMetadata {
  final String id;
  final DrawingMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? templateId;
  final String? thumbnailPath;

  const DrawingMetadata({
    required this.id,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    this.templateId,
    this.thumbnailPath,
  });
}

class StorageService {
  static const _dbName = 'toktok_drawing.db';
  static const _tableName = 'drawings';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            mode INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            template_id TEXT,
            thumbnail_path TEXT
          )
        ''');
      },
    );
  }

  Future<Directory> get _drawingsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'drawings'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> saveDrawing(DrawingData data) async {
    final db = await database;
    final dir = await _drawingsDir;

    // 드로잉 데이터를 JSON 파일로 저장
    final file = File(p.join(dir.path, '${data.id}.json'));
    await file.writeAsString(data.toJsonString());

    // 메타데이터를 SQLite에 저장
    await db.insert(
      _tableName,
      {
        'id': data.id,
        'mode': data.mode.index,
        'created_at': data.createdAt.toIso8601String(),
        'updated_at': data.updatedAt.toIso8601String(),
        'template_id': data.templateId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DrawingData?> loadDrawing(String id) async {
    final dir = await _drawingsDir;
    final file = File(p.join(dir.path, '$id.json'));
    if (!await file.exists()) return null;
    final jsonString = await file.readAsString();
    return DrawingData.fromJsonString(jsonString);
  }

  Future<List<DrawingMetadata>> listDrawings() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'updated_at DESC',
    );
    return rows.map((row) {
      return DrawingMetadata(
        id: row['id'] as String,
        mode: DrawingMode.values[row['mode'] as int],
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        templateId: row['template_id'] as String?,
        thumbnailPath: row['thumbnail_path'] as String?,
      );
    }).toList();
  }

  Future<void> deleteDrawing(String id) async {
    final db = await database;
    final dir = await _drawingsDir;

    // JSON 파일 삭제
    final file = File(p.join(dir.path, '$id.json'));
    if (await file.exists()) {
      await file.delete();
    }

    // 메타데이터 삭제
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateThumbnailPath(String id, String thumbnailPath) async {
    final db = await database;
    await db.update(
      _tableName,
      {'thumbnail_path': thumbnailPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
