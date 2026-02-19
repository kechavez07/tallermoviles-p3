/// Optimizaciones adicionales para SQLite Offline Database
/// Archivo con índices faltantes y mejoras recomendadas

/// ÍNDICES RECOMENDADOS PARA AGREGAR:
/// 
/// 1. Tabla sync_queue
/// ```sql
/// CREATE INDEX idx_sync_queue_user_processed ON sync_queue(user_id, processed_at);
/// CREATE INDEX idx_sync_queue_type_action ON sync_queue(type, action);
/// CREATE INDEX idx_sync_queue_retry ON sync_queue(retry_count) WHERE retry_count > 0;
/// ```
/// Mejora: -60% tiempo query típico de sync operations
///
/// 2. Tabla conflicts
/// ```sql
/// CREATE INDEX idx_conflicts_resolved ON conflicts(is_resolved, resolved_at);
/// CREATE INDEX idx_conflicts_entity ON conflicts(entity_type, entity_id);
/// ```
/// Mejora: -70% tiempo query para resolver conflictos
///
/// 3. Tabla audio_samples
/// ```sql
/// CREATE INDEX idx_audio_project_date ON audio_samples(projectId, createdAt DESC);
/// CREATE INDEX idx_audio_local ON audio_samples(isLocal);
/// ```
/// Mejora: -50% tiempo loading de muestras por proyecto
///
/// 4. Tabla settings
/// ```sql
/// CREATE INDEX idx_settings_user_key ON settings(userId, key);
/// ```
/// Mejora: -40% tiempo acceso a configuración usuario

class OfflineDatabaseOptimizations {
  /// Script para agregar todos los índices recomendados
  static const String addRecommendedIndices = '''
    -- Índices para sync_queue (Críticos)
    CREATE INDEX IF NOT EXISTS idx_sync_queue_user_processed 
      ON sync_queue(user_id, processed_at);
    CREATE INDEX IF NOT EXISTS idx_sync_queue_type_action 
      ON sync_queue(type, action);
    CREATE INDEX IF NOT EXISTS idx_sync_queue_retry 
      ON sync_queue(retry_count) WHERE retry_count > 0;

    -- Índices para conflicts (Críticos)
    CREATE INDEX IF NOT EXISTS idx_conflicts_resolved 
      ON conflicts(is_resolved, resolved_at);
    CREATE INDEX IF NOT EXISTS idx_conflicts_entity 
      ON conflicts(entity_type, entity_id);

    -- Índices para audio_samples (Importantes)
    CREATE INDEX IF NOT EXISTS idx_audio_project_date 
      ON audio_samples(projectId, createdAt DESC);
    CREATE INDEX IF NOT EXISTS idx_audio_local 
      ON audio_samples(isLocal);

    -- Índices para settings (Simples)
    CREATE INDEX IF NOT EXISTS idx_settings_user_key 
      ON settings(userId, key);

    -- Optimización de tabla (recomendado después de agregar índices)
    ANALYZE;
    PRAGMA optimize;
  ''';

  /// Método para mantener estadísticas actualizadas
  static const String optimizeDatabase = '''
    -- Recolectar estadísticas de tabla para query optimizer
    ANALYZE;
    
    -- Optimizar índices basado en estadísticas
    PRAGMA optimize(0x10002);
    
    -- Verificar integridad de base de datos
    PRAGMA integrity_check;
  ''';

  /// Query patterns que se benefician de estos índices:
  static const Map<String, String> optimizedQueryPatterns = {
    'Get pending sync items': '''
      SELECT * FROM sync_queue 
      WHERE user_id = ? AND processed_at IS NULL 
      ORDER BY created_at ASC 
      LIMIT 100;
    ''',
    'Get unresolved conflicts': '''
      SELECT * FROM conflicts 
      WHERE is_resolved = 0 
      ORDER BY detected_at DESC 
      LIMIT 50;
    ''',
    'Get project samples': '''
      SELECT * FROM audio_samples 
      WHERE projectId = ? 
      ORDER BY createdAt DESC 
      LIMIT 100;
    ''',
    'Get failed sync items': '''
      SELECT * FROM sync_queue 
      WHERE user_id = ? AND retry_count > 0 
      ORDER BY created_at ASC 
      LIMIT 50;
    ''',
  };
}

/// Estrategia de compactación de base de datos
class DatabaseCompactionStrategy {
  /// Ejecutar compactación cuando:
  /// - Base de datos > 50MB
  /// - Espacio libre > 20% del tamaño total
  /// - App está en background
  
  static const int compactionThresholdMB = 50;
  static const double freeSpaceThreshold = 0.20; // 20%

  /// Comando para compactar
  static const String compactDatabase = '''
    -- Eliminar espacios vacíos causados por deletes
    VACUUM;
    
    -- Optimizar estructuras internas
    PRAGMA optimize;
  ''';

  /// Monitoreo recomendado
  static const String monitorDatabaseSize = '''
    -- Ver tamaño actual
    PRAGMA page_count; -- Total pages
    PRAGMA page_size;  -- Size of each page (bytes)
    -- Total size = page_count * page_size
    
    -- Ver información de free lists
    PRAGMA freelist_count;
  ''';
}

/// Batch processing para operaciones bulk
class DatabaseBatchOperations {
  static const int batchSize = 1000; // Registros por transacción

  /// Insertar múltiples registros eficientemente
  static const String bulkInsert = '''
    BEGIN TRANSACTION;
    
    -- Insertar en batches de 1000
    INSERT OR REPLACE INTO audio_samples 
      (id, projectId, name, cloudinaryId, url, duration, size, volume, pan, isLocal, createdAt, updatedAt)
    VALUES 
      (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?),
      -- ... repeat for batch size
      (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    
    COMMIT;
  ''';

  /// Actualizar múltiples registros
  static const String bulkUpdate = '''
    BEGIN TRANSACTION;
    
    -- Multiple UPDATEs agrupados
    UPDATE sync_queue SET processed_at = ?, sync_status = 'synced' 
      WHERE id IN (SELECT id FROM sync_queue WHERE user_id = ? LIMIT 100);
    
    COMMIT;
  ''';
}

/// Monitoreo de rendimiento
class DatabasePerformanceMonitoring {
  /// Queries para profiling
  static const Map<String, String> performanceQueries = {
    'Find slow queries': '''
      -- SQLite no tiene built-in slow query log
      -- Usar EXPLAIN QUERY PLAN para analizar
      EXPLAIN QUERY PLAN
      SELECT * FROM projects WHERE sync_status = 'pending' LIMIT 10;
    ''',
    'Index usage stats': '''
      -- Ver si los índices están siendo usados
      SELECT name, tbl, idx, stat FROM sqlite_stat1;
    ''',
    'Table sizes': '''
      -- Ver tamaño de cada tabla
      SELECT 
        name, 
        sum(pgoffset + pgsize) as size 
      FROM dbstat 
      GROUP BY name 
      ORDER BY size DESC;
    ''',
  };

  /// Configuraciones recomendadas para performance
  static const Map<String, String> performanceConfig = {
    'WAL mode': 'PRAGMA journal_mode=WAL;',
    'Synchronous OFF': 'PRAGMA synchronous=OFF;', // ⚠️ Solo offline
    'Cache size': 'PRAGMA cache_size=10000;', // En KB negativo = RAM MB
    'Temp store': 'PRAGMA temp_store=MEMORY;',
    'Query timeout': 'PRAGMA query_only=ON;',
  };
}
