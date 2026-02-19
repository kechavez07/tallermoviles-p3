import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Handler de audio background para audio_service
class AudioServiceHandler extends BaseAudioHandler with SeekHandler {
  /// El reproductor de audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Stream de duración
  final _durationSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

  /// Stream de posición
  final _positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

  /// Stream de modo de reproducción
  final _playbackModeSubject = BehaviorSubject<AudioServicePlaybackMode>.seeded(
    AudioServicePlaybackMode.none,
  );

  /// Constructor
  AudioServiceHandler() {
    _initializeAudio();
  }

  /// Inicializa los listeners de audio
  void _initializeAudio() {
    _audioPlayer.durationStream.pipe(_durationSubject);
    _audioPlayer.positionStream.pipe(_positionSubject);

    // Actualiza el estado de reproducción
    _audioPlayer.playerStateStream.listen((playerState) {
      _updatePlaybackState();
    });

    // Actualiza la duración en el estado de reproducción
    _durationSubject.stream.listen((_) {
      _updatePlaybackState();
    });
  }

  /// Actualiza el estado de reproducción
  void _updatePlaybackState() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (_audioPlayer.playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: switch (_audioPlayer.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: _audioPlayer.playing,
        updatePosition: _positionSubject.value,
        bufferedPosition: _audioPlayer.bufferedPosition,
        speed: _audioPlayer.speed,
        queueIndex: 0,
      ),
    );
  }

  /// Carga un archivo de audio
  Future<void> loadFile(String filePath) async {
    try {
      await _audioPlayer.setFilePath(filePath);
      _updatePlaybackState();
    } catch (e) {
      // Manejar error
    }
  }

  /// Carga desde URL
  Future<void> loadUrl(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      _updatePlaybackState();
    } catch (e) {
      // Manejar error
    }
  }

  /// Reproduce
  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  /// Pausa
  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Detiene
  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Busca una posición
  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Avanza
  @override
  Future<void> fastForward() async {
    final position = _audioPlayer.position + const Duration(seconds: 15);
    await _audioPlayer.seek(position);
  }

  /// Retrocede
  @override
  Future<void> rewind() async {
    final position = _audioPlayer.position - const Duration(seconds: 15);
    await _audioPlayer.seek(position.isNegative ? Duration.zero : position);
  }

  /// Establece la velocidad
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setPlaybackRate(speed);
  }

  /// Limpieza
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _durationSubject.close();
    await _positionSubject.close();
    await _playbackModeSubject.close();
  }
}

/// Inicializa audio_service
Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    handler: AudioServiceHandler(),
    androidNotificationChannelId: 'com.ryanheise.audio_service.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
}
