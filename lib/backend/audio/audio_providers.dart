import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import 'audio_engine.dart';
import 'audio_mixer.dart';
import 'audio_upload_manager.dart';
import 'project_player.dart';

// ==================== SINGLETON AUDIO ENGINE - FIX 1.2 ====================

/// Gestor singleton de AudioEngine con ciclo de vida
class AudioEngineProvider {
  static AudioEngine? _instance;
  static bool _disposed = false;

  static AudioEngine get instance {
    _instance ??= AudioEngine();
    return _instance;
  }

  /// Limpia el engine singleton
  static Future<void> cleanup() async {
    if (_instance != null && !_disposed) {
      _disposed = true;
      await _instance!.dispose();
      _instance = null;
    }
  }

  /// Reinicia el engine
  static void reset() {
    _disposed = false;
    _instance = null;
  }
}

/// Proveedor de servicios de audio usando Provider
/// Este es el punto centralizado para acceder a toda la funcionalidad de audio

/// Provider del AudioEngine usando singleton - FIX 1.2
final audioEngineProvider = Provider<AudioEngine>((ref) {
  return AudioEngineProvider.instance;
});

/// ProjectPlayer provider
final projectPlayerProvider = Provider<ProjectPlayer>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return ProjectPlayer(audioEngine: engine);
});

/// AudioMixer provider
final audioMixerProvider = Provider<AudioMixer>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return AudioMixer(audioEngine: engine);
});

/// AudioUploadManager provider
final audioUploadManagerProvider = Provider<AudioUploadManager>((ref) {
  return AudioUploadProvider.instance;
});

/// Notifier para estado del proyecto de música
class MusicProjectNotifier extends ChangeNotifier {
  /// Proyecto actual
  MusicProject _project;

  /// Engine de audio
  final AudioEngine _audioEngine;

  /// Mixer
  final AudioMixer _mixer;

  /// Player
  final ProjectPlayer _player;

  /// Gestor de upload
  final AudioUploadManager _uploadManager;

  MusicProject get project => _project;
  AudioEngine get audioEngine => _audioEngine;
  AudioMixer get mixer => _mixer;
  ProjectPlayer get player => _player;
  AudioUploadManager get uploadManager => _uploadManager;

  /// Constructor
  MusicProjectNotifier({
    required MusicProject initialProject,
    required AudioEngine audioEngine,
    required AudioMixer mixer,
    required ProjectPlayer player,
    required AudioUploadManager uploadManager,
  })  : _project = initialProject,
        _audioEngine = audioEngine,
        _mixer = mixer,
        _player = player,
        _uploadManager = uploadManager {
    _setupListeners();
  }

  /// Configura los listeners
  void _setupListeners() {
    // Escucha cambios del engine
    _audioEngine.projectStateSubject.listen((project) {
      _project = project;
      notifyListeners();
    });
  }

  /// Crea una pista nueva
  Future<void> addTrack({
    required String name,
    required String instrumentType,
    required String color,
  }) async {
    final newTrack = AudioTrack(
      name: name,
      color: color,
      instrumentType: instrumentType,
    );

    _project = _project.addTrack(newTrack);
    _audioEngine.updateProject(_project);
    notifyListeners();
  }

  /// Elimina una pista
  Future<void> removeTrack(String trackId) async {
    await _mixer.muteTrack(trackId, true);
    final player = _audioEngine.getTrackPlayer(trackId);
    if (player != null) {
      await player.stop();
      await player.dispose();
    }

    _project = _project.removeTrack(trackId);
    _audioEngine.updateProject(_project);
    notifyListeners();
  }

  /// Agrega un loop a una pista
  Future<void> addLoopToTrack(String trackId, Loop loop) async {
    final trackIndex =
        _project.tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex != -1) {
      final updatedTrack = _project.tracks[trackIndex].addLoop(loop);
      final updatedTracks = List<AudioTrack>.from(_project.tracks);
      updatedTracks[trackIndex] = updatedTrack;

      _project = _project.copyWith(tracks: updatedTracks);
      _audioEngine.updateProject(_project);
      notifyListeners();
    }
  }

  /// Elimina un loop de una pista
  Future<void> removeLoopFromTrack(String trackId, String loopId) async {
    final trackIndex =
        _project.tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex != -1) {
      final updatedTrack = _project.tracks[trackIndex].removeLoop(loopId);
      final updatedTracks = List<AudioTrack>.from(_project.tracks);
      updatedTracks[trackIndex] = updatedTrack;

      _project = _project.copyWith(tracks: updatedTracks);
      _audioEngine.updateProject(_project);
      notifyListeners();
    }
  }

  /// Inicia la reproducción
  Future<void> play() async {
    await _player.play();
  }

  /// Pausa
  Future<void> pause() async {
    await _player.pause();
  }

  /// Detiene
  Future<void> stop() async {
    await _player.stop();
  }

  /// Busca
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Establece el BPM
  void setBPM(double bpm) {
    _project = _project.copyWith(bpm: bpm.clamp(30.0, 300.0));
    _audioEngine.updateProject(_project);
    notifyListeners();
  }

  /// Establece volumen maestro
  Future<void> setMasterVolume(double volume) async {
    await _mixer.setMasterVolume(volume);
    _project = _project.copyWith(masterVolume: volume);
    _audioEngine.updateProject(_project);
    notifyListeners();
  }

  /// Limpieza - FIX 1.2: Llamar cleanup cuando se dispone el notifier
  @override
  void dispose() {
    _audioEngine.dispose();
    _mixer.dispose();
    _player.dispose();
    _uploadManager.dispose();
    
    // Cleanup singleton - FIX 1.2
    AudioEngineProvider.cleanup();
    
    super.dispose();
  }
}

/// Provider ChangeNotifier para el proyecto
final musicProjectProvider = ChangeNotifierProvider<MusicProjectNotifier>((ref) {
  final audioEngine = ref.watch(audioEngineProvider);
  final mixer = ref.watch(audioMixerProvider);
  final player = ref.watch(projectPlayerProvider);
  final uploadManager = ref.watch(audioUploadManagerProvider);

  final initialProject = MusicProject(
    name: 'Mi Proyecto de Música',
    projectType: ProjectType.loopMixer,
    bpm: 120.0,
    userId: '', // Se obtendría del usuario autenticado
  );

  return MusicProjectNotifier(
    initialProject: initialProject,
    audioEngine: audioEngine,
    mixer: mixer,
    player: player,
    uploadManager: uploadManager,
  );
});

// Providers específicos de estado que los widgets pueden observar
final projectBPMProvider = StreamProvider<double>((ref) async* {
  final notifier = ref.watch(musicProjectProvider);
  yield notifier.project.bpm;
});

final masterVolumeProvider = StreamProvider<double>((ref) async* {
  final notifier = ref.watch(musicProjectProvider);
  yield notifier.player.audioEngine.masterVolume;
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final notifier = ref.watch(musicProjectProvider);
  return notifier.player.playbackStateSubject.stream;
});

final isPlayingProvider = StreamProvider<bool>((ref) {
  final notifier = ref.watch(musicProjectProvider);
  return notifier.player.isPlayingSubject.stream;
});

final currentPositionProvider = StreamProvider<Duration>((ref) {
  final notifier = ref.watch(musicProjectProvider);
  return notifier.player.currentPositionSubject.stream;
});

final projectDurationProvider = StreamProvider<Duration>((ref) {
  final notifier = ref.watch(musicProjectProvider);
  return notifier.player.projectDurationSubject.stream;
});

final uploadProgressProvider = StreamProvider<UploadProgress>((ref) {
  final uploadManager = ref.watch(audioUploadManagerProvider);
  return uploadManager.uploadProgressSubject.stream;
});
