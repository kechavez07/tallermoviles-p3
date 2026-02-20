import 'package:flutter/material.dart';
import '/backend/app_state_service.dart';

/// Widget que muestra el estado de conexión
class OfflineIndicator extends StatelessWidget {
  final AppStateService appStateService = AppStateService();

  OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: appStateService.isOnlineStream,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        if (isOnline) {
          return SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[700],
            border: Border(
              bottom: BorderSide(color: Colors.orange[900]!),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Modo Offline - Los cambios se sincronizarán',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget que muestra la cola de sincronización
class SyncQueueIndicator extends StatelessWidget {
  final AppStateService appStateService = AppStateService();

  SyncQueueIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: appStateService.syncQueueStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count == 0 || appStateService.isOnline) {
          return SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.all(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              border: Border.all(color: Colors.amber[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.amber[700]),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Sincronizando $count cambios...',
                  style: TextStyle(
                    color: Colors.amber[900],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
