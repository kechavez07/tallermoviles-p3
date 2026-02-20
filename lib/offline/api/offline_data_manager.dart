import 'package:estudio_musica_taller/offline/database/database_manager.dart';
import 'package:estudio_musica_taller/offline/models/local_project.dart';
import 'package:estudio_musica_taller/offline/models/local_track.dart';
import 'package:estudio_musica_taller/offline/models/sync_status.dart';
import 'package:estudio_musica_taller/offline/cache/cache_manager.dart';
import 'package:estudio_musica_taller/offline/sync/sync_service.dart';
import 'package:estudio_musica_taller/offline/models/pending_sync_item.dart';
import 'package:uuid/uuid.dart';

/// API unificada para operaciones offline/online
class OfflineDataManager {
  final DatabaseManager _db = DatabaseManager();
  final CacheManager _cache;
  final SyncService? _syncService;

  OfflineDataManager({
    required CacheManager cache,
    SyncService? syncService,
  })  : _cache = cache,
        _syncService = syncService;

  /// ==================== PROYECTOS ====================

  /// Crear nuevo proyecto
  Future<LocalProject> createProject({
    required String userId,
    required String name,
    required String description,
  }) async {
    final project = LocalProject(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    await _db.insertProject(project);
    await _cache.saveProject(project);

    // Agregar a cola de sincronización
    if (_syncService != null) {
      await _syncService!.addProjectToSync(
        project,
        SyncOperationType.create,
      );
    }

    return project;
  }

  /// Obtener proyecto
  Future<LocalProject?> getProject(String projectId) async {
    return _cache.getProject(projectId);
  }

  /// Obtener todos los proyectos del usuario
  Future<List<LocalProject>> getProjectsByUser(String userId) async {
    return _cache.getProjectsByUser(userId);
  }

  /// Actualizar proyecto
  Future<void> updateProject(LocalProject project) async {
    final updated = project.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    await _db.updateProject(updated);
    await _cache.updateProject(updated);

    // Agregar a cola de sincronización
    if (_syncService != null) {
      await _syncService!.addProjectToSync(
        updated,
        SyncOperationType.update,
      );
    }
  }

  /// Eliminar proyecto
  Future<void> deleteProject(String projectId) async {
    await _db.deleteProject(projectId);
    await _cache.deleteProject(projectId);

    // Agregar eliminación a cola
    if (_syncService != null) {
      final project = await _db.getProject(projectId);
      if (project != null) {
        await _syncService!.addProjectToSync(
          project,
          SyncOperationType.delete,
        );
      }
    }
  }

  /// ==================== PISTAS ====================

  /// Crear nueva pista
  Future<LocalTrack> createTrack({
    required String projectId,
    required String name,
    String? filePath,
    int durationMs = 0,
  }) async {
    final track = LocalTrack(
      id: const Uuid().v4(),
      projectId: projectId,
      name: name,
      filePath: filePath,
      durationMs: durationMs,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    await _db.insertTrack(track);
    await _cache.saveTrack(track);

    // Agregar a cola de sincronización
    if (_syncService != null) {
      await _syncService!.addTrackToSync(
        track,
        SyncOperationType.create,
      );
    }

    return track;
  }

  /// Obtener pista
  Future<LocalTrack?> getTrack(String trackId) async {
    return _cache.getTrack(trackId);
  }

  /// Obtener pistas de un proyecto
  Future<List<LocalTrack>> getTracksByProject(String projectId) async {
    return _cache.getTracksByProject(projectId);
  }

  /// Actualizar pista
  Future<void> updateTrack(LocalTrack track) async {
    final updated = track.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    await _db.updateTrack(updated);
    await _cache.updateTrack(updated);

    // Agregar a cola de sincronización
    if (_syncService != null) {
      await _syncService!.addTrackToSync(
        updated,
        SyncOperationType.update,
      );
    }
  }

  /// Eliminar pista
  Future<void> deleteTrack(String trackId) async {
    await _db.deleteTrack(trackId);
    await _cache.deleteTrack(trackId);
  }

  /// ==================== FAVORITOS ====================

  /// Agregar pista a favoritos
  Future<void> addToFavorites(String projectId, LocalTrack track) async {
    await _cache.markAsFavorite(projectId, track);
  }

  /// Remover pista de favoritos
  Future<void> removeFromFavorites(String projectId, LocalTrack track) async {
    await _cache.unmarkAsFavorite(projectId, track);
  }

  /// Obtener favoritos del proyecto
  Future<List<LocalTrack>> getFavoriteTracks(String projectId) async {
    return _cache.getFavoriteTracks(projectId);
  }

  /// Verificar si es favorita
  bool isFavorite(String trackId) => _cache.isFavorite(trackId);

  /// ==================== CACHÉ ====================

  /// Precachear proyecto y pistas
  Future<void> precacheProject(String projectId) async {
    await _cache.precacheProject(projectId);
  }

  /// Obtener estadísticas del caché
  Map<String, int> getCacheStats() => _cache.getCacheStats();

  /// Limpiar caché expirado
  void cleanupCache() => _cache.clearExpiredCache();

  /// Limpiar todo el caché
  void clearCache() => _cache.clearCache();

  /// ==================== PROYECTOS ABIERTOS ====================

  /// Marcar proyecto como abierto
  void markProjectAsOpen(String projectId) {
    _cache.markProjectAsOpen(projectId);
  }

  /// Marcar proyecto como cerrado
  void markProjectAsClosed(String projectId) {
    _cache.markProjectAsClosed(projectId);
  }

  /// Obtener proyectos abiertos
  List<String> getOpenProjectIds() => _cache.getOpenProjectIds();

  /// ==================== SINCRONIZACIÓN ====================

  /// Obtener estado de sincronización
  Future<Map<String, dynamic>> getSyncStats(String userId) async {
    if (_syncService == null) return {};
    return _syncService!.getSyncStats(userId);
  }

  /// Forzar sincronización
  Future<void> syncNow(String userId) async {
    if (_syncService != null) {
      await _syncService!.forceSynchronization(userId);
    }
  }

  /// ==================== BATCH OPERATIONS ====================

  /// Crear múltiples pistas
  Future<List<LocalTrack>> createMultipleTracks({
    required String projectId,
    required List<Map<String, dynamic>> tracksData,
  }) async {
    final createdTracks = <LocalTrack>[];

    for (final trackData in tracksData) {
      final track = await createTrack(
        projectId: projectId,
        name: trackData['name'] as String,
        filePath: trackData['file_path'] as String?,
        durationMs: trackData['duration_ms'] as int? ?? 0,
      );
      createdTracks.add(track);
    }

    return createdTracks;
  }

  /// Actualizar múltiples pistas
  Future<void> updateMultipleTracks(List<LocalTrack> tracks) async {
    for (final track in tracks) {
      await updateTrack(track);
    }
  }

  /// Eliminar múltiples pistas
  Future<void> deleteMultipleTracks(List<String> trackIds) async {
    for (final trackId in trackIds) {
      await deleteTrack(trackId);
    }
  }

  /// ==================== BÚSQUEDA Y FILTRADO ====================

  /// Buscar proyectos por nombre
  Future<List<LocalProject>> searchProjects(
    String userId,
    String query,
  ) async {
    final projects = await getProjectsByUser(userId);
    return projects
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Buscar pistas por nombre
  Future<List<LocalTrack>> searchTracks(
    String projectId,
    String query,
  ) async {
    final tracks = await getTracksByProject(projectId);
    return tracks
        .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Obtener proyectos pendientes de sincronizar
  Future<List<LocalProject>> getPendingProjects() async {
    return _db.getPendingProjects();
  }

  /// Obtener pistas pendientes de sincronizar
  Future<List<LocalTrack>> getPendingTracks() async {
    return _db.getPendingTracks();
  }

  /// ==================== LIMPIEZA ====================

  /// Limpiar datos sincronizados antiguos
  Future<void> cleanupOldData({int daysOld = 30}) async {
    await _db.cleanupSyncedData(older: Duration(days: daysOld));
  }
}
