/// Enum para representar el estado de sincronización de un registro
enum SyncStatus {
  /// El registro está sincronizado con el servidor
  synced('synced'),
  
  /// El registro tiene cambios pendientes de sincronizar
  pending('pending'),
  
  /// Hay un conflicto que debe resolverse
  conflicted('conflicted'),
  
  /// Error durante la sincronización
  failed('failed');

  final String value;
  const SyncStatus(this.value);

  /// Obtener SyncStatus a partir de un string
  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SyncStatus.synced,
    );
  }
}
