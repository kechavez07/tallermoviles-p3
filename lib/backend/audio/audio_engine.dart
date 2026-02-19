import 'package:rxdart/rxdart.dart';
import '../models/index.dart';
import 'track_player.dart';

/// Motor de audio central que gestiona múltiples pistas
class AudioEngine {
  /// Mapa de reproductores por ID de pista
  final Map<String, TrackPlayer> _trackPlayers = {};

  /// Stream del estado global del proyecto
  final BehaviorSubject<MusicProject> projectStateSubject;

  /// Stream indicando si se está reproduciendo globalmente
  final BehaviorSubject<bool> isPlayingSubject;

  /// Stream de posición global
  final BehaviorSubject<Duration> globalPositionSubject;

  /// Volumen maestro (0.0 a 1.0)
  double _masterVolume = 1.0;

  double get masterVolume => _masterVolume;

  /// Si el motor está sincronizando rastros
  bool _isSynchronizing = false;

  /// Constructor
  AudioEngine()
      : projectStateSubject = BehaviorSubject<MusicProject>.seeded(
          MusicProject(
            name: 'Nuevo Proyecto',
            color: '#FF6B6B',
            instrumentType: 'Mixer',
          ),
        ),
        isPlayingSubject = BehaviorSubject<bool>.seeded(false),
        globalPositionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

  /// Obtiene el proyecto actual
  MusicProject get currentProject => projectStateSubject.value;

  /// Obtiene un reproductor de pista
  TrackPlayer? getTrackPlayer(String trackId) => _trackPlayers[trackId];

  /// Crea o obtiene un reproductor para una pista
  TrackPlayer getOrCreateTrackPlayer(String trackId) {
    return _trackPlayers.putIfAbsent(
      trackId,
      () => TrackPlayer(trackId: trackId),
    );
  }

  /// Carga un audio en una pista
  Future<void> loadAudioForTrack(String trackId, String filePath) async {
    final player = getOrCreateTrackPlayer(trackId);
    await player.loadAudio(filePath);
  }

  /// Carga un audio desde URL en una pista
  Future<void> loadAudioUrlForTrack(String trackId, String url) async {
    final player = getOrCreateTrackPlayer(trackId);
    await player.loadFromUrl(url);
  }

  /// Inicia la reproducción de todas las pistas
  Future<void> play() async {
    try {
      _isSynchronizing = true;
      isPlayingSubject.add(true);

      // Inicia reproducción de todas las pistas habilitadas
      for (final entry in _trackPlayers.entries) {
        final track = currentProject.tracks
            .firstWhere((t) => t.id == entry.key, orElse: () {
          return AudioTrack(
            id: entry.key,
            name: 'Track',
            color: '#000000',
            instrumentType: 'Audio',
          );
        });

        if (track.isEnabled && !track.isMuted) {
          await entry.value.play();
        }
      }

      _isSynchronizing = false;
    } catch (e) {
      _isSynchronizing = false;
      throw Exception('Error reproduciendo: $e');
    }
  }

  /// Pausa todas las pistas
  Future<void> pause() async {
    try {
      isPlayingSubject.add(false);
      for (final player in _trackPlayers.values) {
        await player.pause();
      }
    } catch (e) {
      throw Exception('Error pausando: $e');
    }
  }

  /// Detiene todas las pistas
  Future<void> stop() async {
    try {
      isPlayingSubject.add(false);
      for (final player in _trackPlayers.values) {
        await player.stop();
      }
      globalPositionSubject.add(Duration.zero);
    } catch (e) {
      throw Exception('Error deteniendo: $e');
    }
  }

  /// Busca posición global
  Future<void> seek(Duration position) async {
    try {
      _isSynchronizing = true;

      // Busca en todos los reproductores
      final futures = _trackPlayers.values.map((p) => p.seek(position));
      await Future.wait(futures);

      globalPositionSubject.add(position);
      _isSynchronizing = false;
    } catch (e) {
      _isSynchronizing = false;
      throw Exception('Error buscando: $e');
    }
  }

  /// Establece el volumen maestro
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    // Aplica el volumen maestro a todas las pistas
    for (final player in _trackPlayers.values) {
      final track = currentProject.tracks
          .firstWhere((t) => t.id == player.trackId, orElse: () {
        return AudioTrack(
          id: player.trackId,
          name: 'Track',
          color: '#000000',
          instrumentType: 'Audio',
        );
      });
      final effectiveVolume = track.getEffectiveVolume() * _masterVolume;
      await player.setVolume(effectiveVolume);
    }
  }

  /// Establece el volumen de una pista
  Future<void> setTrackVolume(String trackId, double volume) async {
    final player = getTrackPlayer(trackId);
    if (player != null) {
      final effectiveVolume = volume * _masterVolume;
      await player.setVolume(effectiveVolume);
    }
  }

  /// Silencia una pista
  Future<void> muteTrack(String trackId) async {
    final player = getTrackPlayer(trackId);
    if (player != null) {
      await player.setVolume(0.0);
    }
  }

  /// Dessilencia una pista
  Future<void> unmuteTrack(String trackId, double volume) async {
    final player = getTrackPlayer(trackId);
    if (player != null) {
      final effectiveVolume = volume * _masterVolume;
      await player.setVolume(effectiveVolume);
    }
  }

  /// Actualiza el estado del proyecto
  void updateProject(MusicProject project) {
    projectStateSubject.add(project);
  }

  /// Stream combinado de posición con sincronización - FIX 1.3: Usar master track
  Stream<Duration> get synchronizedPositionStream {
    if (_trackPlayers.isEmpty) {
      return globalPositionSubject.stream;
    }

    // Usar el primer track como master track para sincronización
    final masterTrack = _trackPlayers.values.first;
    
    return masterTrack.positionSubject.stream.handleData((masterPos) {
      // Re-sincronizar el resto de tracks al master si hay desfase > 100ms
      for (final player in _trackPlayers.values) {
        final diff = (player.positionSubject.value - masterPos)
            .inMilliseconds
            .abs();
        
        // Si hay más de 100ms de desfase, sincronizar
        if (diff > 100 && isPlayingSubject.value) {
          player.seek(masterPos).catchError((_) {});
        }
      }
      
      // Actualizar posición global
      if (!globalPositionSubject.isClosed) {
        globalPositionSubject.add(masterPos);
      }
    }).handleError((_) {
      // En caso de error, continuar con stream
    });
  }

  /// Limpia los recursos
  Future<void> dispose() async {
    try {
      await pause();
      for (final player in _trackPlayers.values) {
        await player.dispose();
      }
      _trackPlayers.clear();
      if (!projectStateSubject.isClosed) {
        await projectStateSubject.close();
      }
      if (!isPlayingSubject.isClosed) {
        await isPlayingSubject.close();
      }
      if (!globalPositionSubject.isClosed) {
        await globalPositionSubject.close();
      }
    } catch (e) {
      // Ignorar errores al limpiar
    }
  }
}
