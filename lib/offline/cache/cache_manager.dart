import 'package:flutter/foundation.dart';
import 'package:estudio_musica_taller/offline/database/database_manager.dart';
import 'package:estudio_musica_taller/offline/models/local_project.dart';
import 'package:estudio_musica_taller/offline/models/local_track.dart';

/// Gestor de caché inteligente para proyectos y pistas
class CacheManager extends ChangeNotifier {
  final DatabaseManager _db = DatabaseManager();

  // Caché en memoria
  final Map<String, LocalProject> _projectCache = {};
  final Map<String, List<LocalTrack>> _tracksCache = {};
  final Set<String> _favoritesCache = {};
  final Set<String> _openProjectIds = {};

  // Configuración de caché
  static const Duration cacheExpiration = Duration(minutes: 30);
  static const int maxCachedProjects = 50;
  static const int maxCachedTrackLists = 20;

  // Timestamps de última actualización
  final Map<String, DateTime> _cacheTimestamps = {};

  CacheManager();

  /// ==================== PROYECTOS ====================

  /// Obtener proyecto del caché o base de datos
  Future<LocalProject?> getProject(String projectId) async {
    // Verificar caché en memoria
    if (_projectCache.containsKey(projectId)) {
      final cachedProject = _projectCache[projectId]!;
      if (!_isCacheExpired(projectId)) {
        return cachedProject;
      }
    }

    // Obtener de base de datos
    final project = await _db.getProject(projectId);
    if (project != null) {
      _cacheProject(project);
    }
    return project;
  }

  /// Obtener todos los proyectos de un usuario
  Future<List<LocalProject>> getProjectsByUser(String userId) async {
    final projects = await _db.getProjectsByUser(userId);
    for (final project in projects) {
      _cacheProject(project);
    }
    return projects;
  }

  /// Obtener proyectos pendientes
  Future<List<LocalProject>> getPendingProjects() async {
    return _db.getPendingProjects();
  }

  /// Guardar/actualizar proyecto
  Future<void> saveProject(LocalProject project) async {
    await _db.insertProject(project);
    _cacheProject(project);
    notifyListeners();
  }

  /// Actualizar proyecto
  Future<void> updateProject(LocalProject project) async {
    await _db.updateProject(project);
    _cacheProject(project);
    notifyListeners();
  }

  /// Eliminar proyecto
  Future<void> deleteProject(String projectId) async {
    await _db.deleteProject(projectId);
    _projectCache.remove(projectId);
    _tracksCache.remove(projectId);
    _cacheTimestamps.remove(projectId);
    _openProjectIds.remove(projectId);
    notifyListeners();
  }

  /// Cachear proyecto
  void _cacheProject(LocalProject project) {
    if (_projectCache.length < maxCachedProjects) {
      _projectCache[project.id] = project;
      _cacheTimestamps[project.id] = DateTime.now();
    }
  }

  /// ==================== PISTAS ====================

  /// Obtener pistas de un proyecto
  Future<List<LocalTrack>> getTracksByProject(String projectId) async {
    // Verificar caché en memoria
    if (_tracksCache.containsKey(projectId)) {
      if (!_isCacheExpired('$projectId:tracks')) {
        return _tracksCache[projectId]!;
      }
    }

    // Obtener de base de datos
    final tracks = await _db.getTracksByProject(projectId);
    _cacheTracks(projectId, tracks);
    return tracks;
  }

  /// Obtener pista individual
  Future<LocalTrack?> getTrack(String trackId) async {
    // Buscar en todos los cachés
    for (final tracks in _tracksCache.values) {
      final track = tracks.firstWhere(
        (t) => t.id == trackId,
        orElse: () => throw Exception('Not found'),
      );
      if (track.id == trackId) return track;
    }

    // Si no está en caché, obtener de BD
    return _db.getTrack(trackId);
  }

  /// Guardar/actualizar pista
  Future<void> saveTrack(LocalTrack track) async {
    await _db.insertTrack(track);
    _updateTracksCache(track.projectId, track);
    notifyListeners();
  }

  /// Actualizar pista
  Future<void> updateTrack(LocalTrack track) async {
    await _db.updateTrack(track);
    _updateTracksCache(track.projectId, track);
    notifyListeners();
  }

  /// Eliminar pista
  Future<void> deleteTrack(String trackId) async {
    await _db.deleteTrack(trackId);

    // Eliminar de todos los cachés
    for (final entry in _tracksCache.entries) {
      entry.value.removeWhere((t) => t.id == trackId);
    }

    _favoritesCache.remove(trackId);
    notifyListeners();
  }

  /// Cachear pistas
  void _cacheTracks(String projectId, List<LocalTrack> tracks) {
    if (_tracksCache.length < maxCachedTrackLists) {
      _tracksCache[projectId] = tracks;
      _cacheTimestamps['$projectId:tracks'] = DateTime.now();
    }
  }

  /// Actualizar pista en caché
  void _updateTracksCache(String projectId, LocalTrack track) {
    if (_tracksCache.containsKey(projectId)) {
      final index = _tracksCache[projectId]!.indexWhere((t) => t.id == track.id);
      if (index >= 0) {
        _tracksCache[projectId]![index] = track;
      } else {
        _tracksCache[projectId]!.add(track);
      }
    }
  }

  /// ==================== FAVORITOS ====================

  /// Obtener favoritos de un proyecto
  Future<List<LocalTrack>> getFavoriteTracks(String projectId) async {
    final tracks = await _db.getFavoriteTracks(projectId);
    for (final track in tracks) {
      _favoritesCache.add(track.id);
    }
    return tracks;
  }

  /// Marcar pista como favorita
  Future<void> markAsFavorite(String projectId, LocalTrack track) async {
    final updated = track.copyWith(isFavorite: true);
    await updateTrack(updated);
    _favoritesCache.add(track.id);
    notifyListeners();
  }

  /// Desmarcar como favorita
  Future<void> unmarkAsFavorite(String projectId, LocalTrack track) async {
    final updated = track.copyWith(isFavorite: false);
    await updateTrack(updated);
    _favoritesCache.remove(track.id);
    notifyListeners();
  }

  /// Verificar si es favorita
  bool isFavorite(String trackId) => _favoritesCache.contains(trackId);

  /// ==================== PROYECTOS ABIERTOS ====================

  /// Marcar proyecto como abierto
  void markProjectAsOpen(String projectId) {
    _openProjectIds.add(projectId);
    notifyListeners();
  }

  /// Marcar proyecto como cerrado
  void markProjectAsClosed(String projectId) {
    _openProjectIds.remove(projectId);
    notifyListeners();
  }

  /// Obtener proyectos abiertos
  List<String> getOpenProjectIds() => List.unmodifiable(_openProjectIds);

  /// Verificar si proyecto está abierto
  bool isProjectOpen(String projectId) => _openProjectIds.contains(projectId);

  /// ==================== UTILIDADES ====================

  /// Verificar si caché expiró
  bool _isCacheExpired(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return true;

    final now = DateTime.now();
    return now.difference(timestamp) > cacheExpiration;
  }

  /// Limpiar caché
  void clearCache() {
    _projectCache.clear();
    _tracksCache.clear();
    _favoritesCache.clear();
    _cacheTimestamps.clear();
    notifyListeners();
  }

  /// Limpiar caché expirado
  void clearExpiredCache() {
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      return now.difference(timestamp) > cacheExpiration;
    });

    // Limpiar proyectos sin timestamp
    _projectCache.removeWhere(
      (id, _) => !_cacheTimestamps.containsKey(id),
    );

    // Limpiar listas de pistas sin timestamp
    _tracksCache.removeWhere(
      (id, _) => !_cacheTimestamps.containsKey('$id:tracks'),
    );

    notifyListeners();
  }

  /// Obtener estadísticas del caché
  Map<String, int> getCacheStats() {
    return {
      'cachedProjects': _projectCache.length,
      'cachedTrackLists': _tracksCache.length,
      'favoriteCount': _favoritesCache.length,
      'openProjects': _openProjectIds.length,
      'totalCacheEntries': _cacheTimestamps.length,
    };
  }

  /// Precachear proyecto y sus pistas
  Future<void> precacheProject(String projectId) async {
    final project = await getProject(projectId);
    if (project != null) {
      await getTracksByProject(projectId);
      markProjectAsOpen(projectId);
      notifyListeners();
    }
  }

  /// Invalidar caché de un proyecto
  void invalidateProjectCache(String projectId) {
    _projectCache.remove(projectId);
    _tracksCache.remove(projectId);
    _cacheTimestamps.remove(projectId);
    _cacheTimestamps.remove('$projectId:tracks');
    notifyListeners();
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
