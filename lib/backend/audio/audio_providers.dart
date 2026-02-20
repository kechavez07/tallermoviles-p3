import 'package:audio_service/audio_service.dart' as as;
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

/// Helper class to provide all audio related providers
class AudioProviders {
  static List<Provider> getBasicProviders() => [
    Provider<AudioEngine>(create: (_) => AudioEngineProvider.instance),
    ProxyProvider<AudioEngine, ProjectPlayer>(
      update: (_, engine, __) => ProjectPlayer(audioEngine: engine),
    ),
    ProxyProvider<AudioEngine, AudioMixer>(
      update: (_, engine, __) => AudioMixer(audioEngine: engine),
    ),
    Provider<AudioUploadManager>(create: (_) => AudioUploadProvider.instance),
  ];

  static List<dynamic> getAllProviders() => [
    ...getBasicProviders(),
    ChangeNotifierProxyProvider4<AudioEngine, AudioMixer, ProjectPlayer, AudioUploadManager, MusicProjectNotifier>(
      create: (context) => MusicProjectNotifier(
        initialProject: MusicProject(
          name: 'Mi Proyecto de Música',
          projectType: ProjectType.loopMixer,
          bpm: 120.0,
          userId: '',
        ),
        audioEngine: context.read<AudioEngine>(),
        mixer: context.read<AudioMixer>(),
        player: context.read<ProjectPlayer>(),
        uploadManager: context.read<AudioUploadManager>(),
      ),
      update: (context, engine, mixer, player, uploadManager, previous) =>
        previous ?? MusicProjectNotifier(
          initialProject: MusicProject(
            name: 'Mi Proyecto de Música',
            projectType: ProjectType.loopMixer,
            bpm: 120.0,
            userId: '',
          ),
          audioEngine: engine,
          mixer: mixer,
          player: player,
          uploadManager: uploadManager,
        ),
    ),
    // State providers
    StreamProvider<double>(
      create: (context) => context.read<MusicProjectNotifier>().projectStateSubject.map((p) => p.bpm),
      initialData: 120.0,
    ),
    StreamProvider<double>(
      create: (context) => context.read<MusicProjectNotifier>().projectStateSubject.map((p) => p.masterVolume),
      initialData: 1.0,
    ),
    StreamProvider<PlaybackState>(
      create: (context) => context.read<MusicProjectNotifier>().player.playbackStateSubject.stream,
      initialData: const PlaybackState(),
    ),
    StreamProvider<bool>(
      create: (context) => context.read<MusicProjectNotifier>().player.isPlayingSubject.stream,
      initialData: false,
    ),
    StreamProvider<Duration>(
      create: (context) => context.read<MusicProjectNotifier>().player.currentPositionSubject.stream,
      initialData: Duration.zero,
    ),
    StreamProvider<Duration>(
      create: (context) => context.read<MusicProjectNotifier>().player.projectDurationSubject.stream,
      initialData: Duration.zero,
    ),
    StreamProvider<UploadProgress>(
      create: (context) => context.read<AudioUploadManager>().uploadProgressSubject.stream,
      initialData: UploadProgress(
        status: UploadStatus.idle,
        progress: 0.0,
      ),
    ),
  ];
}
