import '../models/conflict_record.dart';
import '../models/local_project.dart';
import '../models/local_track.dart';
import 'package:uuid/uuid.dart';

/// Servicio para resolver conflictos de sincronización
class ConflictResolver {
  static const uuid = Uuid();

  /// Detectar conflicto entre versión local y remota
  static ConflictRecord detectConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> localVersion,
    required Map<String, dynamic> remoteVersion,
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
  }) {
    return ConflictRecord(
      id: uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      localTimestamp: localTimestamp,
      remoteTimestamp: remoteTimestamp,
      detectedAt: DateTime.now(),
      isResolved: false,
    );
  }

  /// Resolver conflicto usando la estrategia Last-Write-Wins
  static Map<String, dynamic> resolveLastWriteWins({
    required Map<String, dynamic> localVersion,
    required Map<String, dynamic> remoteVersion,
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
  }) {
    if (remoteTimestamp.isAfter(localTimestamp)) {
      return remoteVersion;
    } else if (localTimestamp.isAfter(remoteTimestamp)) {
      return localVersion;
    } else {
      // Misma fecha, usar versión remota como predeterminada
      return remoteVersion;
    }
  }

  /// Resolver conflicto usando versiones
  static Map<String, dynamic> resolveByVersioning({
    required Map<String, dynamic> localVersion,
    required Map<String, dynamic> remoteVersion,
    String? localVersionField = 'version',
    String? remoteVersionField = 'version',
  }) {
    final localVer = localVersion[localVersionField] as int? ?? 0;
    final remoteVer = remoteVersion[remoteVersionField] as int? ?? 0;

    if (remoteVer > localVer) {
      return remoteVersion;
    } else if (localVer > remoteVer) {
      return localVersion;
    } else {
      // Misma versión, usar local
      return localVersion;
    }
  }

  /// Fusionar cambios automáticamente (estrategia inteligente)
  static Map<String, dynamic> mergeVersions(
    Map<String, dynamic> localVersion,
    Map<String, dynamic> remoteVersion,
  ) {
    final merged = {...remoteVersion};

    // Mantener cambios locales en campos específicos
    final fieldsToKeepLocal = [
      'isFavorite',
      'is_favorite',
      'position',
      'localNotes',
    ];

    for (final field in fieldsToKeepLocal) {
      if (localVersion.containsKey(field)) {
        merged[field] = localVersion[field];
      }
    }

    return merged;
  }

  /// Detectar campos específicos en conflicto
  static List<String> detectConflictingFields(
    Map<String, dynamic> localVersion,
    Map<String, dynamic> remoteVersion,
  ) {
    final conflictingFields = <String>[];
    final allKeys = {...localVersion.keys, ...remoteVersion.keys};

    for (final key in allKeys) {
      final localValue = localVersion[key];
      final remoteValue = remoteVersion[key];

      if (localValue != remoteValue) {
        conflictingFields.add(key);
      }
    }

    return conflictingFields;
  }

  /// Resolver proyectos en conflicto
  static LocalProject resolveProjectConflict(
    LocalProject localProject,
    Map<String, dynamic> remoteProjectData,
    ConflictResolutionStrategy strategy,
  ) {
    final resolvedData = applyStrategy(
      localProject.toMap(),
      remoteProjectData,
      strategy,
      localProject.updatedAt,
      DateTime.parse(remoteProjectData['updated_at'] as String? ?? ''),
    );

    return LocalProject(
      id: localProject.id,
      userId: localProject.userId,
      name: resolvedData['name'] as String? ?? localProject.name,
      description: resolvedData['description'] as String? ?? localProject.description,
      createdAt: localProject.createdAt,
      updatedAt: localProject.updatedAt,
      syncStatus: localProject.syncStatus,
      firebaseId: resolvedData['firebase_id'] as String? ?? localProject.firebaseId,
    );
  }

  /// Resolver pistas en conflicto
  static LocalTrack resolveTrackConflict(
    LocalTrack localTrack,
    Map<String, dynamic> remoteTrackData,
    ConflictResolutionStrategy strategy,
  ) {
    final resolvedData = applyStrategy(
      localTrack.toMap(),
      remoteTrackData,
      strategy,
      localTrack.updatedAt,
      DateTime.parse(remoteTrackData['updated_at'] as String? ?? ''),
    );

    return LocalTrack(
      id: localTrack.id,
      projectId: localTrack.projectId,
      name: resolvedData['name'] as String? ?? localTrack.name,
      filePath: resolvedData['file_path'] as String? ?? localTrack.filePath,
      durationMs: resolvedData['duration_ms'] as int? ?? localTrack.durationMs,
      position: resolvedData['position'] as int? ?? localTrack.position,
      createdAt: localTrack.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: localTrack.syncStatus,
      firebaseId: resolvedData['firebase_id'] as String? ?? localTrack.firebaseId,
      isFavorite: resolvedData['is_favorite'] as bool? ?? localTrack.isFavorite,
      artistName: resolvedData['artist_name'] as String? ?? localTrack.artistName,
      genre: resolvedData['genre'] as String? ?? localTrack.genre,
    );
  }

  /// Aplicar estrategia de resolución
  static Map<String, dynamic> applyStrategy(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    ConflictResolutionStrategy strategy,
    DateTime localTimestamp,
    DateTime remoteTimestamp,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return resolveLastWriteWins(
          localVersion: localData,
          remoteVersion: remoteData,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
        );

      case ConflictResolutionStrategy.keepLocal:
        return localData;

      case ConflictResolutionStrategy.keepRemote:
        return remoteData;

      case ConflictResolutionStrategy.manual:
        // En caso manual, retornar local por defecto
        return localData;
    }
  }

  /// Crear registro de conflicto resuelto
  static ConflictRecord createResolvedConflict(
    ConflictRecord conflict,
    ConflictResolutionStrategy strategy,
  ) {
    return conflict.copyWith(
      resolutionStrategy: strategy,
      isResolved: true,
      resolvedAt: DateTime.now(),
    );
  }
}
