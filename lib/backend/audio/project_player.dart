import 'package:rxdart/rxdart.dart';
import '../models/index.dart';
import 'audio_engine.dart';
import 'track_synchronizer.dart';

/// Gestor de reproducción del proyecto musical
class ProjectPlayer {
  /// Motor de audio
  final AudioEngine audioEngine;

  /// Sincronizador de pistas
  late TrackSynchronizer synchronizer;

  /// Stream de estado actual del proyecto
  final BehaviorSubject<PlaybackState> playbackStateSubject;

  /// Stream de duración del proyecto
  final BehaviorSubject<Duration> projectDurationSubject;

  /// Stream de posición actual
  final BehaviorSubject<Duration> currentPositionSubject;

  /// Stream indicando si está reproduciendo
  final BehaviorSubject<bool> isPlayingSubject;

  /// Stream indicando si se está cargando
  final BehaviorSubject<bool> isLoadingSubject;

  /// Velocidad de reproducción
  double _playbackRate = 1.0;

  double get playbackRate => _playbackRate;

  /// Constructor
  ProjectPlayer({required this.audioEngine})
      : playbackStateSubject = BehaviorSubject<PlaybackState>.seeded(
          const PlaybackState(status: PlaybackStatus.stopped),
        ),
        projectDurationSubject = BehaviorSubject<Duration>.seeded(Duration.zero),
        currentPositionSubject = BehaviorSubject<Duration>.seeded(Duration.zero),
        isPlayingSubject = BehaviorSubject<bool>.seeded(false),
        isLoadingSubject = BehaviorSubject<bool>.seeded(false) {
    synchronizer = TrackSynchronizer(audioEngine: audioEngine);
    _setupStreams();
  }

  /// Configura los streams
  void _setupStreams() {
    // Actualiza la duración cuando cambia el proyecto
    audioEngine.projectStateSubject.listen((project) {
      final duration = project.getMaxDuration();
      projectDurationSubject.add(duration);
    });

    // Sincroniza posición
    synchronizer.startSynchronization();
    Rx.combineLatest2(
      audioEngine.isPlayingSubject,
      audioEngine.globalPositionSubject,
      (isPlaying, position) {
        return position;
      },
    ).listen((position) {
      currentPositionSubject.add(position);
      
      // Actualiza el estado general
      final status = audioEngine.isPlayingSubject.value
          ? PlaybackStatus.playing
          : PlaybackStatus.paused;
      playbackStateSubject.add(
        playbackStateSubject.value.copyWith(
          status: status,
          position: position,
          duration: projectDurationSubject.value,
          playbackRate: _playbackRate,
        ),
      );
    });

    // Actualiza isPlaying
    audioEngine.isPlayingSubject.listen((isPlaying) {
      isPlayingSubject.add(isPlaying);
      final status = isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused;
      playbackStateSubject.add(
        playbackStateSubject.value.copyWith(status: status),
      );
    });
  }

  /// Carga los audios de todas las pistas
  Future<void> loadProject() async {
    try {
      isLoadingSubject.add(true);

      for (final track in audioEngine.currentProject.tracks) {
        if (track.loops.isNotEmpty) {
          final firstLoop = track.loops.first;

          // Si tiene URL de Firebase, usa eso
          if (firstLoop.firebaseUrl != null) {
            await audioEngine.loadAudioUrlForTrack(track.id, firstLoop.firebaseUrl!);
          }
          // Si no, intenta cargar desde la ruta local
          else if (firstLoop.audioPath.isNotEmpty) {
            await audioEngine.loadAudioForTrack(track.id, firstLoop.audioPath);
          }
        }
      }

      isLoadingSubject.add(false);
    } catch (e) {
      isLoadingSubject.add(false);
      playbackStateSubject.add(
        playbackStateSubject.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error cargando proyecto: $e',
        ),
      );
      throw Exception('Error cargando proyecto: $e');
    }
  }

  /// Inicia la reproducción
  Future<void> play() async {
    try {
      await audioEngine.play();
    } catch (e) {
      playbackStateSubject.add(
        playbackStateSubject.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error reproduciendo: $e',
        ),
      );
      throw Exception('Error reproduciendo: $e');
    }
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    try {
      await audioEngine.pause();
    } catch (e) {
      playbackStateSubject.add(
        playbackStateSubject.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error pausando: $e',
        ),
      );
      throw Exception('Error pausando: $e');
    }
  }

  /// Detiene la reproducción
  Future<void> stop() async {
    try {
      await audioEngine.stop();
    } catch (e) {
      playbackStateSubject.add(
        playbackStateSubject.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error deteniendo: $e',
        ),
      );
      throw Exception('Error deteniendo: $e');
    }
  }

  /// Busca una posición específica
  Future<void> seek(Duration position) async {
    try {
      final maxDuration = projectDurationSubject.value;
      final clampedPosition = position.compareTo(maxDuration) > 0
          ? maxDuration
          : (position.compareTo(Duration.zero) < 0 ? Duration.zero : position);
      
      await audioEngine.seek(clampedPosition);
    } catch (e) {
      playbackStateSubject.add(
        playbackStateSubject.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'Error buscando: $e',
        ),
      );
      throw Exception('Error buscando: $e');
    }
  }

  /// Avanza X segundos
  Future<void> fastForward(int seconds) async {
    final newPosition = currentPositionSubject.value +
        Duration(seconds: seconds);
    await seek(newPosition);
  }

  /// Retrocede X segundos
  Future<void> rewind(int seconds) async {
    final newPosition = currentPositionSubject.value -
        Duration(seconds: seconds);
    await seek(newPosition);
  }

  /// Establece la velocidad de reproducción
  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate.clamp(0.5, 2.0);
    
    // Aplicar a todos los reproductores de pista
    for (final track in audioEngine.currentProject.tracks) {
      final player = audioEngine.getTrackPlayer(track.id);
      if (player != null) {
        await player.setSpeed(_playbackRate);
      }
    }

    playbackStateSubject.add(
      playbackStateSubject.value.copyWith(playbackRate: _playbackRate),
    );
  }

  /// Obtiene el porcentaje de progreso (0.0 a 1.0)
  double getProgress() {
    final duration = projectDurationSubject.value.inMilliseconds;
    if (duration == 0) return 0.0;
    
    final position = currentPositionSubject.value.inMilliseconds;
    return (position / duration).clamp(0.0, 1.0);
  }

  /// Obtiene tiempo restante
  Duration getRemainingTime() {
    return projectDurationSubject.value - currentPositionSubject.value;
  }

  /// Formatea la duración a string (mm:ss)
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Limpieza
  Future<void> dispose() async {
    synchronizer.dispose();
    await audioEngine.dispose();
    await playbackStateSubject.close();
    await projectDurationSubject.close();
    await currentPositionSubject.close();
    await isPlayingSubject.close();
    await isLoadingSubject.close();
  }
}
