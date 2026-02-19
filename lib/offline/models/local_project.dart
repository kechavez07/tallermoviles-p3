import 'package:estudio_musica_taller/offline/models/sync_status.dart';

/// Modelo que representa un proyecto de música almacenado localmente
class LocalProject {
  final String id;
  final String userId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final int version; // ✅ NUEVO: Para detección de conflictos
  final SyncStatus syncStatus;
  final String? firebaseId; // ID del documento en Firestore
  final Map<String, dynamic> metadata;

  LocalProject({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.version = 0, // ✅ NUEVO
    this.syncStatus = SyncStatus.pending,
    this.firebaseId,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  /// Crear LocalProject a partir de Map (para base de datos)
  factory LocalProject.fromMap(Map<String, dynamic> map) {
    return LocalProject(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      syncedAt: map['synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['synced_at'] as int)
          : null,
      version: map['version'] as int? ?? 0, // ✅ NUEVO
      syncStatus: SyncStatus.fromString(map['sync_status'] as String? ?? 'pending'),
      firebaseId: map['firebase_id'] as String?,
      metadata: (map['metadata'] as String?)?.isNotEmpty == true
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
    );
  }

  /// Convertir LocalProject a Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'synced_at': syncedAt?.millisecondsSinceEpoch,
      'version': version, // ✅ NUEVO
      'sync_status': syncStatus.value,
      'firebase_id': firebaseId,
      'metadata': metadata.isEmpty ? null : metadata.toString(),
    };
  }

  /// Crear una copia con cambios
  LocalProject copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    int? version, // ✅ NUEVO
    SyncStatus? syncStatus,
    String? firebaseId,
    Map<String, dynamic>? metadata,
  }) {
    return LocalProject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      version: version ?? this.version, // ✅ NUEVO
      syncStatus: syncStatus ?? this.syncStatus,
      firebaseId: firebaseId ?? this.firebaseId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'LocalProject(id: $id, name: $name, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalProject &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
