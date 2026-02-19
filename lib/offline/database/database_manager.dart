import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:estudio_musica_taller/offline/models/local_project.dart';
import 'package:estudio_musica_taller/offline/models/local_track.dart';
import 'package:estudio_musica_taller/offline/models/pending_sync_item.dart';
import 'package:estudio_musica_taller/offline/models/conflict_record.dart';

/// Gestor centralizado de la base de datos SQLite
class DatabaseManager {
  static const String _dbName = 'estudio_musica.db';
  static const int _dbVersion = 1;

  // Nombres de tablas
  static const String tableProjects = 'local_projects';
  static const String tableTracks = 'local_tracks';
  static const String tableSyncQueue = 'pending_sync_queue';
  static const String tableConflicts = 'conflict_records';

  static final DatabaseManager _instance = DatabaseManager._internal();

  Database? _database;

  DatabaseManager._internal();

  factory DatabaseManager() {
    return _instance;
  }

  /// Obtener instancia de la base de datos
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inicializar la base de datos
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// Crear tablas en la base de datos
  Future<void> _createTables(Database db, int version) async {
    // Tabla de proyectos locales
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProjects (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER,
        version INTEGER DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        firebase_id TEXT,
        metadata TEXT,
        UNIQUE(user_id, firebase_id)
      )
    ''');

    // Tabla de pistas locales
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTracks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        name TEXT NOT NULL,
        file_path TEXT,
        duration_ms INTEGER DEFAULT 0,
        position INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER,
        version INTEGER DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        firebase_id TEXT,
        is_favorite INTEGER DEFAULT 0,
        artist_name TEXT,
        genre TEXT,
        FOREIGN KEY(project_id) REFERENCES $tableProjects(id) ON DELETE CASCADE,
        UNIQUE(project_id, firebase_id)
      )
    ''');

    // Tabla de cola de sincronización
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSyncQueue (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        data TEXT,
        created_at INTEGER NOT NULL,
        processed_at INTEGER,
        retry_count INTEGER DEFAULT 0,
        error TEXT
      )
    ''');

    // Tabla de conflictos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableConflicts (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_version TEXT,
        remote_version TEXT,
        local_timestamp INTEGER NOT NULL,
        remote_timestamp INTEGER NOT NULL,
        detected_at INTEGER NOT NULL,
        resolution_strategy TEXT,
        is_resolved INTEGER DEFAULT 0,
        resolved_at INTEGER
      )
    ''');

    // Crear índices para optimizar búsquedas
    await db.execute('CREATE INDEX IF NOT EXISTS idx_projects_user_id ON $tableProjects(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_projects_sync_status ON $tableProjects(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_project_id ON $tableTracks(project_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_sync_status ON $tableTracks(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_user_id ON $tableSyncQueue(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_processed ON $tableSyncQueue(processed_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conflicts_entity ON $tableConflicts(entity_type, entity_id)');
  }

  /// Actualizar estructura de la base de datos en futuras versiones
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Aquí irían las migraciones futuras
  }

  /// ==================== OPERACIONES CON PROYECTOS ====================

  /// Insertar un nuevo proyecto
  Future<void> insertProject(LocalProject project) async {
    final db = await database;
    await db.insert(
      tableProjects,
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtener proyecto por ID
  Future<LocalProject?> getProject(String projectId) async {
    final db = await database;
    final result = await db.query(
      tableProjects,
      where: 'id = ?',
      whereArgs: [projectId],
    );
    return result.isNotEmpty ? LocalProject.fromMap(result.first) : null;
  }

  /// Obtener todos los proyectos de un usuario
  Future<List<LocalProject>> getProjectsByUser(String userId) async {
    final db = await database;
    final result = await db.query(
      tableProjects,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => LocalProject.fromMap(map)).toList();
  }

  /// Obtener proyectos pendientes de sincronizar
  Future<List<LocalProject>> getPendingProjects() async {
    final db = await database;
    final result = await db.query(
      tableProjects,
      where: "sync_status IN ('pending', 'conflicted')",
      orderBy: 'updated_at ASC',
    );
    return result.map((map) => LocalProject.fromMap(map)).toList();
  }

  /// Actualizar proyecto
  Future<void> updateProject(LocalProject project) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        tableProjects,
        project.toMap(),
        where: 'id = ?',
        whereArgs: [project.id],
      );
    });
  }

  /// Eliminar proyecto
  Future<void> deleteProject(String projectId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        tableProjects,
        where: 'id = ?',
        whereArgs: [projectId],
      );
      // Las pistas se eliminan por cascada
    });
  }

  /// ==================== OPERACIONES CON PISTAS ====================

  /// Insertar una nueva pista
  Future<void> insertTrack(LocalTrack track) async {
    final db = await database;
    await db.insert(
      tableTracks,
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtener pista por ID
  Future<LocalTrack?> getTrack(String trackId) async {
    final db = await database;
    final result = await db.query(
      tableTracks,
      where: 'id = ?',
      whereArgs: [trackId],
    );
    return result.isNotEmpty ? LocalTrack.fromMap(result.first) : null;
  }

  /// Obtener todas las pistas de un proyecto
  Future<List<LocalTrack>> getTracksByProject(String projectId) async {
    final db = await database;
    final result = await db.query(
      tableTracks,
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'position ASC, created_at ASC',
    );
    return result.map((map) => LocalTrack.fromMap(map)).toList();
  }

  /// Obtener pistas pendientes de sincronizar
  Future<List<LocalTrack>> getPendingTracks() async {
    final db = await database;
    final result = await db.query(
      tableTracks,
      where: "sync_status IN ('pending', 'conflicted')",
      orderBy: 'updated_at ASC',
    );
    return result.map((map) => LocalTrack.fromMap(map)).toList();
  }

  /// Obtener favoritos
  Future<List<LocalTrack>> getFavoriteTracks(String projectId) async {
    final db = await database;
    final result = await db.query(
      tableTracks,
      where: 'project_id = ? AND is_favorite = 1',
      whereArgs: [projectId],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => LocalTrack.fromMap(map)).toList();
  }

  /// Actualizar pista
  Future<void> updateTrack(LocalTrack track) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        tableTracks,
        track.toMap(),
        where: 'id = ?',
        whereArgs: [track.id],
      );
    });
  }

  /// Eliminar pista
  Future<void> deleteTrack(String trackId) async {
    final db = await database;
    await db.delete(
      tableTracks,
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  /// ==================== OPERACIONES CON COLA DE SINCRONIZACIÓN ====================

  /// Agregar elemento a la cola de sincronización
  Future<void> addToSyncQueue(PendingSyncItem item) async {
    final db = await database;
    await db.insert(
      tableSyncQueue,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtener elementos pendientes de si ncronizar
  Future<List<PendingSyncItem>> getPendingSyncItems(
    String userId, {
    int limit = 100,
  }) async {
    final db = await database;
    final result = await db.query(
      tableSyncQueue,
      where: 'user_id = ? AND processed_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return result.map((map) => PendingSyncItem.fromMap(map)).toList();
  }

  /// Actualizar elemento de sincronización
  Future<void> updateSyncItem(PendingSyncItem item) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        tableSyncQueue,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    });
  }

  /// Marcar como procesado
  Future<void> markSyncItemAsProcessed(String itemId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        tableSyncQueue,
        {'processed_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [itemId],
      );
    });
  }

  /// Eliminar de la cola
  Future<void> removeSyncItem(String itemId) async {
    final db = await database;
    await db.delete(
      tableSyncQueue,
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// ==================== OPERACIONES CON CONFLICTOS ====================

  /// Crear registro de conflicto
  Future<void> createConflict(ConflictRecord conflict) async {
    final db = await database;
    await db.insert(
      tableConflicts,
      conflict.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtener conflicto por ID
  Future<ConflictRecord?> getConflict(String conflictId) async {
    final db = await database;
    final result = await db.query(
      tableConflicts,
      where: 'id = ?',
      whereArgs: [conflictId],
    );
    return result.isNotEmpty ? ConflictRecord.fromMap(result.first) : null;
  }

  /// Obtener todos los conflictos no resueltos
  Future<List<ConflictRecord>> getUnresolvedConflicts() async {
    final db = await database;
    final result = await db.query(
      tableConflicts,
      where: 'is_resolved = 0',
      orderBy: 'detected_at DESC',
    );
    return result.map((map) => ConflictRecord.fromMap(map)).toList();
  }

  /// Actualizar conflicto
  Future<void> updateConflict(ConflictRecord conflict) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        tableConflicts,
        conflict.toMap(),
        where: 'id = ?',
        whereArgs: [conflict.id],
      );
    });
  }

  /// Eliminar conflicto
  Future<void> deleteConflict(String conflictId) async {
    final db = await database;
    await db.delete(
      tableConflicts,
      where: 'id = ?',
      whereArgs: [conflictId],
    );
  }

  /// ==================== OPERACIONES DE MANTENIMIENTO ====================

  /// Obtener estadísticas de sincronización
  Future<Map<String, dynamic>> getSyncStats(String userId) async {
    final db = await database;

    final pendingProjects = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableProjects WHERE user_id = ? AND sync_status = ?',
      [userId, 'pending'],
    );

    final pendingTracks = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableTracks WHERE sync_status = ?',
      ['pending'],
    );

    final syncQueue = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableSyncQueue WHERE user_id = ? AND processed_at IS NULL',
      [userId],
    );

    final conflicts = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableConflicts WHERE is_resolved = 0',
    );

    return {
      'pendingProjects': pendingProjects.first['count'] ?? 0,
      'pendingTracks': pendingTracks.first['count'] ?? 0,
      'syncQueueItems': syncQueue.first['count'] ?? 0,
      'unresolvedConflicts': conflicts.first['count'] ?? 0,
    };
  }

  /// Limpiar datos sincronizados antiguos (más de 7 días por defecto)
  Future<void> cleanupSyncedData({Duration older = const Duration(days: 7)}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(older).millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Eliminar proyectos sincronizados antiguos
      await txn.delete(
        tableProjects,
        where: 'sync_status = \'synced\' AND synced_at IS NOT NULL AND synced_at < ?',
        whereArgs: [cutoffTime],
      );

      // Eliminar pistas sincronizadas antiguas
      await txn.delete(
        tableTracks,
        where: 'sync_status = \'synced\' AND synced_at IS NOT NULL AND synced_at < ?',
        whereArgs: [cutoffTime],
      );

      // Eliminar queue items procesados antiguos
      await txn.delete(
        tableSyncQueue,
        where: 'processed_at IS NOT NULL AND processed_at < ?',
        whereArgs: [cutoffTime],
      );

      // Eliminar conflictos resueltos antiguos
      await txn.delete(
        tableConflicts,
        where: 'is_resolved = 1 AND resolved_at IS NOT NULL AND resolved_at < ?',
        whereArgs: [cutoffTime],
      );
    });

    // Vacuum para liberar espacio
    await db.execute('VACUUM');
  }

  /// Cerrar la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
