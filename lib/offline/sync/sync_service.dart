import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudio_musica_taller/offline/connectivity/connectivity_manager.dart';
import 'package:estudio_musica_taller/offline/database/database_manager.dart';
import 'package:estudio_musica_taller/offline/models/pending_sync_item.dart';
import 'package:estudio_musica_taller/offline/models/sync_status.dart';
import 'package:estudio_musica_taller/offline/models/local_project.dart';
import 'package:estudio_musica_taller/offline/models/local_track.dart';

/// Callback para actualizaciones de progreso de sincronización
typedef SyncProgressCallback = Function(int processed, int total);

/// Callback para errores de sincronización
typedef SyncErrorCallback = Function(String error);

/// Servicio de sincronización offline-first
class SyncService extends ChangeNotifier {
  final DatabaseManager _db = DatabaseManager();
  final ConnectivityManager _connectivityManager;

  bool _isSyncing = false;
  int _syncProgress = 0;
  String _syncStatus = 'idle';

  SyncProgressCallback? _onSyncProgress;
  SyncErrorCallback? _onSyncError;
  Function()? _onSyncComplete;

  // Configuración
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  static const Duration syncCheckInterval = Duration(minutes: 5);

  SyncService(this._connectivityManager) {
    _initialize();
  }

  bool get isSyncing => _isSyncing;
  int get syncProgress => _syncProgress;
  String get syncStatus => _syncStatus;

  /// Inicializar servicio de sincronización
  void _initialize() {
    _connectivityManager.onConnectivityChanged((state) {
      if (state == NetworkState.online && !_isSyncing) {
        debugPrint('[SyncService] Conexión detectada, iniciando sincronización...');
        synchronizeAll();
      }
    });
  }

  /// Registrar callback en cambios de progreso
  void onSyncProgress(SyncProgressCallback callback) {
    _onSyncProgress = callback;
  }

  /// Registrar callback en errores
  void onSyncError(SyncErrorCallback callback) {
    _onSyncError = callback;
  }

  /// Registrar callback on sincronización completa
  void onSyncComplete(Function() callback) {
    _onSyncComplete = callback;
  }

  /// Sincronizar todo (proyectos, pistas y cola)
  Future<void> synchronizeAll({String? userId}) async {
    if (_isSyncing) {
      debugPrint('[SyncService] Ya hay una sincronización en progreso');
      return;
    }

    if (_connectivityManager.isOffline) {
      debugPrint('[SyncService] Sin conexión, no se puede sincronizar');
      return;
    }

    _isSyncing = true;
    _syncStatus = 'syncing';
    _syncProgress = 0;
    notifyListeners();

    try {
      // 1. Obtener elementos pendientes
      final pendingItems = userId != null
          ? await _db.getPendingSyncItems(userId)
          : await _db.getPendingSyncItems(''); // Usar usuario actual

      if (pendingItems.isEmpty) {
        _syncStatus = 'completed';
        _isSyncing = false;
        notifyListeners();
        _onSyncComplete?.call();
        return;
      }

      // 2. Procesar cada elemento
      for (int i = 0; i < pendingItems.length; i++) {
        final item = pendingItems[i];
        await _processSyncItem(item);

        _syncProgress = ((i + 1) / pendingItems.length * 100).toInt();
        _onSyncProgress?.call(i + 1, pendingItems.length);
        notifyListeners();
      }

      // 3. Limpiar datos antiguos
      await _db.cleanupSyncedData();

      _syncStatus = 'completed';
      _onSyncComplete?.call();
      debugPrint('[SyncService] Sincronización completada exitosamente');
    } catch (e) {
      _syncStatus = 'error';
      _onSyncError?.call('Error durante sincronización: $e');
      debugPrint('[SyncService] Error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Procesar un elemento de la cola de sincronización
  Future<void> _processSyncItem(PendingSyncItem item) async {
    try {
      // Verificar si ya fue procesado
      if (item.processedAt != null) {
        return;
      }

      // Intentar procesamiento con reintentos
      bool success = false;
      PendingSyncItem currentItem = item;

      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          // ✅ NUEVO: Sincronización real con Firebase
          success = await _syncToFirebase(item);

          if (success) {
            // Marcar como actualizado en local
            if (item.entityType == 'project') {
              final project = await _db.getProject(item.entityId);
              if (project != null) {
                await _db.updateProject(
                  project.copyWith(
                    syncStatus: SyncStatus.synced,
                    syncedAt: DateTime.now(),
                  ),
                );
              }
            } else if (item.entityType == 'track') {
              final track = await _db.getTrack(item.entityId);
              if (track != null) {
                await _db.updateTrack(
                  track.copyWith(
                    syncStatus: SyncStatus.synced,
                    syncedAt: DateTime.now(),
                  ),
                );
              }
            }

            // Marcar como procesado
            await _db.markSyncItemAsProcessed(item.id);
            break;
          }
        } catch (e) {
          debugPrint('[SyncService] Intento $attempt falló: $e');

          // Guardar error en el intento
          currentItem = item.copyWith(
            retryCount: attempt + 1,
            error: e.toString(),
          );

          // Esperar antes de reintentar
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelay);
          }
        }
      }

      // Si no fue exitoso después de reintentos
      if (!success) {
        await _db.updateSyncItem(currentItem);
        _onSyncError?.call(
          'No se pudo sincronizar ${item.entityType}: ${item.entityId}',
        );
      }
    } catch (e) {
      debugPrint('[SyncService] Error procesando item: $e');
    }
  }

  /// Sincronizar elemento a Firebase (IMPLEMENTACIÓN REAL)
  Future<bool> _syncToFirebase(PendingSyncItem item) async {
    try {
      // ✅ NUEVO: Implementación real con Firebase
      final firestore = FirebaseFirestore.instance;

      switch (item.operationType) {
        case SyncOperationType.create:
          debugPrint('[SyncService] Creating $item.entityType: ${item.entityId}');
          await firestore
              .collection(item.entityType + 's') // 'projects' o 'tracks'
              .doc(item.entityId)
              .set({
                ...item.data,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
          break;

        case SyncOperationType.update:
          debugPrint('[SyncService] Updating $item.entityType: ${item.entityId}');
          await firestore
              .collection(item.entityType + 's')
              .doc(item.entityId)
              .update({
                ...item.data,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          break;

        case SyncOperationType.delete:
          debugPrint('[SyncService] Deleting $item.entityType: ${item.entityId}');
          await firestore
              .collection(item.entityType + 's')
              .doc(item.entityId)
              .delete();
          break;
      }

      debugPrint('[SyncService] Firebase sync successful for ${item.entityId}');
      return true;
    } catch (e) {
      debugPrint('[SyncService] Firebase sync error: $e');
      return false;
    }
  }

  /// Agregar proyecto a la cola de sincronización
  Future<void> addProjectToSync(
    LocalProject project,
    SyncOperationType operationType,
  ) async {
    final syncItem = PendingSyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${project.id}',
      userId: project.userId,
      operationType: operationType,
      entityType: 'project',
      entityId: project.id,
      data: project.toMap(),
      createdAt: DateTime.now(),
    );

    await _db.addToSyncQueue(syncItem);
    notifyListeners();

    // Intentar sincronización inmediata si hay conexión
    if (_connectivityManager.isOnline) {
      synchronizeAll(userId: project.userId);
    }
  }

  /// Agregar pista a la cola de sincronización
  Future<void> addTrackToSync(
    LocalTrack track,
    SyncOperationType operationType,
  ) async {
    final syncItem = PendingSyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${track.id}',
      userId: track.projectId,
      operationType: operationType,
      entityType: 'track',
      entityId: track.id,
      data: track.toMap(),
      createdAt: DateTime.now(),
    );

    await _db.addToSyncQueue(syncItem);
    notifyListeners();

    // Intentar sincronización inmediata si hay conexión
    if (_connectivityManager.isOnline) {
      synchronizeAll();
    }
  }

  /// Obtener estadísticas de sincronización
  Future<Map<String, dynamic>> getSyncStats(String userId) async {
    return _db.getSyncStats(userId);
  }

  /// Obtener elementos pendientes
  Future<List<PendingSyncItem>> getPendingItems(String userId) async {
    return _db.getPendingSyncItems(userId);
  }

  /// Forzar sincronización
  Future<void> forceSynchronization(String userId) async {
    if (_connectivityManager.isOnline) {
      await synchronizeAll(userId: userId);
    }
  }

  /// Reintentar elemento fallido
  Future<void> retryFailedItem(String itemId) async {
    final db = DatabaseManager();
    final pendingItems = await db.getPendingSyncItems('');

    final itemToRetry = pendingItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('Item no encontrado'),
    );

    await _processSyncItem(itemToRetry);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
