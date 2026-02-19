/// Tipos de operaciones que pueden estar pendientes de sincronización
enum SyncOperationType {
  create('create'),
  update('update'),
  delete('delete');

  final String value;
  const SyncOperationType(this.value);

  static SyncOperationType fromString(String value) {
    return SyncOperationType.values.firstWhere(
      (op) => op.value == value,
      orElse: () => SyncOperationType.create,
    );
  }
}

/// Modelo que representa un elemento en la cola de sincronización
class PendingSyncItem {
  final String id;
  final String userId;
  final SyncOperationType operationType;
  final String entityType; // 'project' o 'track'
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? processedAt;
  final int retryCount;
  final String? error;

  PendingSyncItem({
    required this.id,
    required this.userId,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.createdAt,
    this.processedAt,
    this.retryCount = 0,
    this.error,
  });

  /// Crear PendingSyncItem a partir de Map (para base de datos)
  factory PendingSyncItem.fromMap(Map<String, dynamic> map) {
    return PendingSyncItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      operationType: SyncOperationType.fromString(map['operation_type'] as String),
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      data: (map['data'] as String?)?.isNotEmpty == true
          ? Map<String, dynamic>.from(map['data'] as Map)
          : {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      processedAt: map['processed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['processed_at'] as int)
          : null,
      retryCount: map['retry_count'] as int? ?? 0,
      error: map['error'] as String?,
    );
  }

  /// Convertir PendingSyncItem a Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'operation_type': operationType.value,
      'entity_type': entityType,
      'entity_id': entityId,
      'data': data.isEmpty ? null : data.toString(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'processed_at': processedAt?.millisecondsSinceEpoch,
      'retry_count': retryCount,
      'error': error,
    };
  }

  /// Crear una copia con cambios
  PendingSyncItem copyWith({
    String? id,
    String? userId,
    SyncOperationType? operationType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? processedAt,
    int? retryCount,
    String? error,
  }) {
    return PendingSyncItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'PendingSyncItem(id: $id, operationType: $operationType, entityId: $entityId)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSyncItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
