/// Estrategias para resolver conflictos
enum ConflictResolutionStrategy {
  lastWriteWins('last_write_wins'),
  keepLocal('keep_local'),
  keepRemote('keep_remote'),
  manual('manual');

  final String value;
  const ConflictResolutionStrategy(this.value);

  static ConflictResolutionStrategy fromString(String value) {
    return ConflictResolutionStrategy.values.firstWhere(
      (strategy) => strategy.value == value,
      orElse: () => ConflictResolutionStrategy.lastWriteWins,
    );
  }
}

/// Modelo que representa un conflicto durante la sincronización
class ConflictRecord {
  final String id;
  final String entityType; // 'project' o 'track'
  final String entityId;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> remoteVersion;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final DateTime detectedAt;
  final ConflictResolutionStrategy? resolutionStrategy;
  final bool isResolved;
  final DateTime? resolvedAt;

  ConflictRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localVersion,
    required this.remoteVersion,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.detectedAt,
    this.resolutionStrategy,
    this.isResolved = false,
    this.resolvedAt,
  });

  /// Crear ConflictRecord a partir de Map (para base de datos)
  factory ConflictRecord.fromMap(Map<String, dynamic> map) {
    return ConflictRecord(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      localVersion: (map['local_version'] as String?)?.isNotEmpty == true
          ? Map<String, dynamic>.from(map['local_version'] as Map)
          : {},
      remoteVersion: (map['remote_version'] as String?)?.isNotEmpty == true
          ? Map<String, dynamic>.from(map['remote_version'] as Map)
          : {},
      localTimestamp:
          DateTime.fromMillisecondsSinceEpoch(map['local_timestamp'] as int),
      remoteTimestamp:
          DateTime.fromMillisecondsSinceEpoch(map['remote_timestamp'] as int),
      detectedAt: DateTime.fromMillisecondsSinceEpoch(map['detected_at'] as int),
      resolutionStrategy: map['resolution_strategy'] != null
          ? ConflictResolutionStrategy.fromString(map['resolution_strategy'] as String)
          : null,
      isResolved: (map['is_resolved'] as int?) == 1,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['resolved_at'] as int)
          : null,
    );
  }

  /// Convertir ConflictRecord a Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'local_version': localVersion.isEmpty ? null : localVersion.toString(),
      'remote_version': remoteVersion.isEmpty ? null : remoteVersion.toString(),
      'local_timestamp': localTimestamp.millisecondsSinceEpoch,
      'remote_timestamp': remoteTimestamp.millisecondsSinceEpoch,
      'detected_at': detectedAt.millisecondsSinceEpoch,
      'resolution_strategy': resolutionStrategy?.value,
      'is_resolved': isResolved ? 1 : 0,
      'resolved_at': resolvedAt?.millisecondsSinceEpoch,
    };
  }

  /// Crear una copia con cambios
  ConflictRecord copyWith({
    String? id,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? localVersion,
    Map<String, dynamic>? remoteVersion,
    DateTime? localTimestamp,
    DateTime? remoteTimestamp,
    DateTime? detectedAt,
    ConflictResolutionStrategy? resolutionStrategy,
    bool? isResolved,
    DateTime? resolvedAt,
  }) {
    return ConflictRecord(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localVersion: localVersion ?? this.localVersion,
      remoteVersion: remoteVersion ?? this.remoteVersion,
      localTimestamp: localTimestamp ?? this.localTimestamp,
      remoteTimestamp: remoteTimestamp ?? this.remoteTimestamp,
      detectedAt: detectedAt ?? this.detectedAt,
      resolutionStrategy: resolutionStrategy ?? this.resolutionStrategy,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  String toString() {
    return 'ConflictRecord(id: $id, entityId: $entityId, isResolved: $isResolved)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConflictRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
