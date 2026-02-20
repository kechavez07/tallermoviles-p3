import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import '../models/index.dart';

/// Gestor de reproducción de audio para una pista individual
class TrackPlayer {
  /// ID de la pista
  final String trackId;

  /// Reproductor de audio de just_audio
  final AudioPlayer audioPlayer;

  /// Stream del estado de reproducción
  final BehaviorSubject<PlaybackState> playbackStateSubject;

  /// Stream de posición
  final BehaviorSubject<Duration> positionSubject;

  /// Stream de duración
  final BehaviorSubject<Duration> durationSubject;

  /// Volumen actual (0.0 - 1.0)
  double _volume = 1.0;

  /// Lista de subscripciones para cleanup - FIX 1.1
  final List<StreamSubscription> _subscriptions = [];

  /// Flag para control de ciclo de vida - FIX 1.1
  bool _isDisposed = false;

  double get volume => _volume;

  /// Constructor
  TrackPlayer({
    required this.trackId,
  })  : audioPlayer = AudioPlayer(),
        playbackStateSubject = BehaviorSubject<PlaybackState>.seeded(
          const PlaybackState(status: PlaybackStatus.stopped),
        ),
        positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero),
        durationSubject = BehaviorSubject<Duration>.seeded(Duration.zero) {
    _setupListeners();
  }

  /// Configura los listeners del audioPlayer - FIX 1.1: Guardar subscripciones
  void _setupListeners() {
    // Escuchar cambios de estado
    _subscriptions.add(
      audioPlayer.playerStateStream.listen(
        (playerState) {
          if (_isDisposed) return;
          final status = playerState.playing
              ? PlaybackStatus.playing
              : (playerState.processingState == ProcessingState.completed
                  ? PlaybackStatus.stopped
                  : PlaybackStatus.paused);

          final currentState = playbackStateSubject.value;
          if (!_isDisposed) {
            playbackStateSubject.add(currentState.copyWith(status: status));
          }
        },
        onError: (e) {
          if (!_isDisposed) {
            final currentState = playbackStateSubject.value;
            playbackStateSubject.add(
              currentState.copyWith(
                status: PlaybackStatus.error,
                errorMessage: e.toString(),
              ),
            );
          }
        },
      ),
    );

    // Escuchar posición
    _subscriptions.add(
      audioPlayer.positionStream.listen(
        (position) {
          if (!_isDisposed) {
            positionSubject.add(position);
            final currentState = playbackStateSubject.value;
            playbackStateSubject.add(currentState.copyWith(position: position));
          }
        },
        onError: (e) {},
      ),
    );

    // Escuchar duración
    _subscriptions.add(
      audioPlayer.durationStream.listen(
        (duration) {
          if (!_isDisposed && duration != null) {
            durationSubject.add(duration);
            final currentState = playbackStateSubject.value;
            playbackStateSubject.add(currentState.copyWith(duration: duration));
          }
        },
        onError: (e) {},
      ),
    );

    // Escuchar errores generales
    _subscriptions.add(
      audioPlayer.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          if (!_isDisposed) {
            final currentState = playbackStateSubject.value;
            playbackStateSubject.add(
              currentState.copyWith(
                status: PlaybackStatus.error,
                errorMessage: e.toString(),
              ),
            );
          }
        },
      ),
    );
  }

  /// Carga un archivo de audio
  Future<void> loadAudio(String filePath) async {
    try {
      await audioPlayer.setFilePath(filePath);
    } catch (e) {
      final currentState = playbackStateSubject.value;
      playbackStateSubject.add(
        currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error cargando audio: $e',
        ),
      );
    }
  }

  /// Carga desde URL
  Future<void> loadFromUrl(String url) async {
    try {
      await audioPlayer.setUrl(url);
    } catch (e) {
      final currentState = playbackStateSubject.value;
      playbackStateSubject.add(
        currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error cargando URL: $e',
        ),
      );
    }
  }

  /// Reproduce el audio
  Future<void> play() async {
    try {
      await audioPlayer.play();
    } catch (e) {
      final currentState = playbackStateSubject.value;
      playbackStateSubject.add(
        currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error reproduciendo: $e',
        ),
      );
    }
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    try {
      await audioPlayer.pause();
    } catch (e) {
      final currentState = playbackStateSubject.value;
      playbackStateSubject.add(
        currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error pausando: $e',
        ),
      );
    }
  }

  /// Detiene la reproducción
  Future<void> stop() async {
    try {
      await audioPlayer.stop();
      positionSubject.add(Duration.zero);
    } catch (e) {
      final currentState = playbackStateSubject.value;
      playbackStateSubject.add(
        currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error deteniendo: $e',
        ),
      );
    }
  }

  /// Busca una posición
  Future<void> seek(Duration position) async {
    try {
      await audioPlayer.seek(position);
    } catch (e) {
      final currentState = playbackStateSubject.value;
      playbackStateSubject.add(
        currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error buscando posición: $e',
        ),
      );
    }
  }

  /// Establece el volumen (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await audioPlayer.setVolume(_volume);
    } catch (e) {
      // Ignorar errores de volumen
    }
  }

  /// Establece la velocidad de reproducción
  Future<void> setSpeed(double rate) async {
    try {
      await audioPlayer.setSpeed(rate);
      final currentState = playbackStateSubject.value;
      playbackStateSubject.add(currentState.copyWith(playbackRate: rate));
    } catch (e) {
      final currentState = playbackStateSubject.value;
      playbackStateSubject.add(
        currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error cambiando velocidad: $e',
        ),
      );
    }
  }

  /// Limpia recursos con manejo seguro - FIX 1.1: Cancelar todas las subscripciones
  Future<void> dispose() async {
    if (_isDisposed) return; // Evitar double dispose
    _isDisposed = true;

    try {
      // Cancelar todas las subscripciones primero
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      // Detener reproducción
      try {
        await audioPlayer.stop();
      } catch (_) {}

      // Limpiar subjects
      if (!playbackStateSubject.isClosed) {
        await playbackStateSubject.close();
      }
      if (!positionSubject.isClosed) {
        await positionSubject.close();
      }
      if (!durationSubject.isClosed) {
        await durationSubject.close();
      }

      // Finalmente limpiar el player
      await audioPlayer.dispose();
    } catch (e) {
      // Ignorar errores durante cleanup
    }
  }
}
