import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  static Database? _database;

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'musical_studio.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSync INTEGER DEFAULT 0,
        data TEXT,
        thumbnail TEXT
      )
    ''');

    // Audio samples table
    await db.execute('''
      CREATE TABLE audio_samples (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL,
        cloudinaryId TEXT,
        url TEXT,
        duration REAL,
        size INTEGER,
        volume REAL DEFAULT 1.0,
        pan REAL DEFAULT 0.0,
        isLocal INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY(projectId) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE favorite_samples (
        id TEXT PRIMARY KEY,
        sampleId TEXT NOT NULL,
        userId TEXT NOT NULL,
        addedAt TEXT NOT NULL,
        FOREIGN KEY(sampleId) REFERENCES audio_samples(id) ON DELETE CASCADE
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT,
        updatedAt TEXT NOT NULL,
        UNIQUE(userId, key)
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for performance
    await db.execute(
        'CREATE INDEX idx_projects_userId ON projects(userId)');
    await db.execute(
        'CREATE INDEX idx_audio_samples_projectId ON audio_samples(projectId)');
    await db.execute(
        'CREATE INDEX idx_favorite_samples_userId ON favorite_samples(userId)');
  }

  // ===================== PROJECT OPERATIONS =====================

  Future<void> createProject({
    required String id,
    required String name,
    required String userId,
    String? description,
    String? thumbnail,
  }) async {
    final db = await database;
    await db.insert(
      'projects',
      {
        'id': id,
        'name': name,
        'description': description,
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'thumbnail': thumbnail,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProject(String projectId) async {
    final db = await database;
    final result = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [projectId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getUserProjects(String userId) async {
    final db = await database;
    return db.query(
      'projects',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
    );
  }

  Future<void> updateProject({
    required String projectId,
    String? name,
    String? description,
    String? thumbnail,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (thumbnail != null) updates['thumbnail'] = thumbnail;

    await db.update(
      'projects',
      updates,
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<void> deleteProject(String projectId) async {
    final db = await database;
    await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  // ===================== AUDIO SAMPLE OPERATIONS =====================

  Future<void> addAudioSample({
    required String sampleId,
    required String projectId,
    required String fileName,
    required String filePath,
    String? cloudinaryId,
    String? url,
    double? duration,
    int? size,
  }) async {
    final db = await database;
    await db.insert(
      'audio_samples',
      {
        'id': sampleId,
        'projectId': projectId,
        'fileName': fileName,
        'filePath': filePath,
        'cloudinaryId': cloudinaryId,
        'url': url,
        'duration': duration,
        'size': size,
        'volume': 1.0,
        'pan': 0.0,
        'isLocal': cloudinaryId == null ? 1 : 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getProjectSamples(
      String projectId) async {
    final db = await database;
    return db.query(
      'audio_samples',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<void> updateSampleVolume(String sampleId, double volume) async {
    final db = await database;
    await db.update(
      'audio_samples',
      {
        'volume': volume,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sampleId],
    );
  }

  Future<void> updateSamplePan(String sampleId, double pan) async {
    final db = await database;
    await db.update(
      'audio_samples',
      {
        'pan': pan,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sampleId],
    );
  }

  Future<void> deleteSample(String sampleId) async {
    final db = await database;
    await db.delete(
      'audio_samples',
      where: 'id = ?',
      whereArgs: [sampleId],
    );
  }

  // ===================== FAVORITES OPERATIONS =====================

  Future<void> addToFavorites(String sampleId, String userId) async {
    final db = await database;
    await db.insert(
      'favorite_samples',
      {
        'id': '${userId}_${sampleId}',
        'sampleId': sampleId,
        'userId': userId,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFromFavorites(String sampleId, String userId) async {
    final db = await database;
    await db.delete(
      'favorite_samples',
      where: 'sampleId = ? AND userId = ?',
      whereArgs: [sampleId, userId],
    );
  }

  Future<List<Map<String, dynamic>>> getUserFavoriteSamples(
      String userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT s.* FROM audio_samples s
      JOIN favorite_samples f ON s.id = f.sampleId
      WHERE f.userId = ?
      ORDER BY f.addedAt DESC
    ''', [userId]);
  }

  // ===================== SETTINGS OPERATIONS =====================

  Future<void> saveSetting({
    required String userId,
    required String key,
    required String value,
  }) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'id': '${userId}_$key',
        'userId': userId,
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String userId, String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'userId = ? AND key = ?',
      whereArgs: [userId, key],
    );
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }

  Future<Map<String, String>> getUserSettings(String userId) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return {for (var row in results) row['key'] as String: row['value'] as String};
  }

  // ===================== SYNC OPERATIONS =====================

  Future<void> addToSyncQueue({
    required String type, // 'project', 'sample', 'favorite'
    required String action, // 'create', 'update', 'delete'
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'id': '${DateTime.now().millisecondsSinceEpoch}_${type}_$action',
        'type': type,
        'action': action,
        'data': jsonEncode(data),
        'timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return db.query(
      'sync_queue',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> markAsSynced(String syncId) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [syncId],
    );
  }

  Future<void> clearSyncedItems() async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'synced = ?',
      whereArgs: [1],
    );
  }

  // ===================== DATABASE OPERATIONS =====================

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> resetDatabase() async {
    await closeDatabase();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'musical_studio.db');
    await deleteDatabase(path);
  }
}
