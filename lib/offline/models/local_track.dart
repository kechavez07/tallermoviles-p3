import 'package:estudio_musica_taller/offline/models/sync_status.dart';

/// Modelo que representa una pista de audio almacenada localmente
class LocalTrack {
  final String id;
  final String projectId;
  final String name;
  final String? filePath;
  final int durationMs;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final int version; // ✅ NUEVO: Para detección de conflictos
  final SyncStatus syncStatus;
  final String? firebaseId; // ID del documento en Firestore
  final bool isFavorite;
  final String? artistName;
  final String? genre;

  LocalTrack({
    required this.id,
    required this.projectId,
    required this.name,
    this.filePath,
    this.durationMs = 0,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.version = 0, // ✅ NUEVO
    this.syncStatus = SyncStatus.pending,
    this.firebaseId,
    this.isFavorite = false,
    this.artistName,
    this.genre,
  });

  /// Crear LocalTrack a partir de Map (para base de datos)
  factory LocalTrack.fromMap(Map<String, dynamic> map) {
    return LocalTrack(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      name: map['name'] as String,
      filePath: map['file_path'] as String?,
      durationMs: map['duration_ms'] as int? ?? 0,
      position: map['position'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      syncedAt: map['synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['synced_at'] as int)
          : null,
      version: map['version'] as int? ?? 0, // ✅ NUEVO
      syncStatus: SyncStatus.fromString(map['sync_status'] as String? ?? 'pending'),
      firebaseId: map['firebase_id'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      artistName: map['artist_name'] as String?,
      genre: map['genre'] as String?,
    );
  }

  /// Convertir LocalTrack a Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'file_path': filePath,
      'duration_ms': durationMs,
      'position': position,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'synced_at': syncedAt?.millisecondsSinceEpoch,
      'version': version, // ✅ NUEVO
      'sync_status': syncStatus.value,
      'firebase_id': firebaseId,
      'is_favorite': isFavorite ? 1 : 0,
      'artist_name': artistName,
      'genre': genre,
    };
  }

  /// Crear una copia con cambios
  LocalTrack copyWith({
    String? id,
    String? projectId,
    String? name,
    String? filePath,
    int? durationMs,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    int? version, // ✅ NUEVO
    SyncStatus? syncStatus,
    String? firebaseId,
    bool? isFavorite,
    String? artistName,
    String? genre,
  }) {
    return LocalTrack(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      version: version ?? this.version, // ✅ NUEVO
      syncStatus: syncStatus ?? this.syncStatus,
      firebaseId: firebaseId ?? this.firebaseId,
      isFavorite: isFavorite ?? this.isFavorite,
      artistName: artistName ?? this.artistName,
      genre: genre ?? this.genre,
    );
  }

  @override
  String toString() {
    return 'LocalTrack(id: $id, name: $name, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTrack &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
