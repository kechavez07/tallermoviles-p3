import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'audio_engine.dart';

/// Sincronizador de pistas para mantener todas reproduciéndose al mismo tiempo
class TrackSynchronizer {
  /// Motor de audio
  final AudioEngine audioEngine;

  /// Timer de sincronización
  Timer? _syncTimer;

  /// Tolerancia de sincronización en milisegundos
  final int syncToleranceMs = 50;

  /// Intervalo de verificación de sincronización
  final Duration syncCheckInterval = const Duration(milliseconds: 100);

  /// Stream indicando desincronización
  final BehaviorSubject<bool> isOutOfSyncSubject =
      BehaviorSubject<bool>.seeded(false);

  /// Constructor
  TrackSynchronizer({required this.audioEngine});

  /// Inicia la sincronización automática
  void startSynchronization() {
    _syncTimer = Timer.periodic(syncCheckInterval, (_) {
      _checkSync();
    });
  }

  /// Detiene la sincronización automática
  void stopSynchronization() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Verifica si las pistas están sincronizadas
  void _checkSync() {
    if (audioEngine.currentProject.tracks.isEmpty) {
      isOutOfSyncSubject.add(false);
      return;
    }

    final players = audioEngine.currentProject.tracks
        .where((t) => t.isEnabled && !t.isMuted)
        .map((t) => audioEngine.getTrackPlayer(t.id))
        .whereType<TrackPlayer>()
        .toList();

    if (players.length <= 1) {
      isOutOfSyncSubject.add(false);
      return;
    }

    // Verifica si todas las posiciones están dentro del rango de tolerancia
    final positions = players.map((p) => p.positionSubject.value).toList();
    final minPos = positions.reduce((a, b) => a < b ? a : b);
    final maxPos = positions.reduce((a, b) => a > b ? a : b);

    final difference = maxPos.inMilliseconds - minPos.inMilliseconds;
    final isOutOfSync = difference > syncToleranceMs;

    isOutOfSyncSubject.add(isOutOfSync);

    // Si está muy desincronizado, intenta resincroni
    if (isOutOfSync && audioEngine.isPlayingSubject.value) {
      _resynchronize(players, minPos);
    }
  }

  /// Resincroniza las pistas
  void _resynchronize(List<TrackPlayer> players, Duration targetPosition) async {
    // Busca todos a la misma posición
    for (final player in players) {
      if ((player.positionSubject.value.inMilliseconds -
              targetPosition.inMilliseconds)
          .abs() > syncToleranceMs) {
        await player.seek(targetPosition);
      }
    }
  }

  /// Obtiene la posición promedio de todas las pistas
  Duration getAveragePosition() {
    if (audioEngine.currentProject.tracks.isEmpty) {
      return Duration.zero;
    }

    final players = audioEngine.currentProject.tracks
        .where((t) => t.isEnabled && !t.isMuted)
        .map((t) => audioEngine.getTrackPlayer(t.id))
        .whereType<TrackPlayer>()
        .toList();

    if (players.isEmpty) {
      return Duration.zero;
    }

    int totalMs = 0;
    for (final player in players) {
      totalMs += player.positionSubject.value.inMilliseconds;
    }

    return Duration(milliseconds: totalMs ~/ players.length);
  }

  /// Obtiene la posición máxima
  Duration getMaxPosition() {
    if (audioEngine.currentProject.tracks.isEmpty) {
      return Duration.zero;
    }

    final players = audioEngine.currentProject.tracks
        .where((t) => t.isEnabled && !t.isMuted)
        .map((t) => audioEngine.getTrackPlayer(t.id))
        .whereType<TrackPlayer>()
        .toList();

    if (players.isEmpty) {
      return Duration.zero;
    }

    Duration maxPos = Duration.zero;
    for (final player in players) {
      final pos = player.positionSubject.value;
      if (pos > maxPos) {
        maxPos = pos;
      }
    }

    return maxPos;
  }

  /// Obtiene el rango de desincronización
  Duration getSyncRange() {
    if (audioEngine.currentProject.tracks.isEmpty) {
      return Duration.zero;
    }

    final players = audioEngine.currentProject.tracks
        .where((t) => t.isEnabled && !t.isMuted)
        .map((t) => audioEngine.getTrackPlayer(t.id))
        .whereType<TrackPlayer>()
        .toList();

    if (players.length <= 1) {
      return Duration.zero;
    }

    final positions = players.map((p) => p.positionSubject.value).toList();
    final minPos = positions.reduce((a, b) => a < b ? a : b);
    final maxPos = positions.reduce((a, b) => a > b ? a : b);

    return maxPos - minPos;
  }

  /// Limpieza
  void dispose() {
    stopSynchronization();
    isOutOfSyncSubject.close();
  }
}

// Necesitamos importar TrackPlayer para el type checking
import 'track_player.dart';
