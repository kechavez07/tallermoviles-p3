import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'logger_service.dart';

class AudioTrack {
  final String id;
  final String name;
  final String filePath;
  late final AudioPlayer audioPlayer;
  double volume = 1.0;
  double pan = 0.0;
  bool isMuted = false;
  bool isPlaying = false;

  AudioTrack({
    required this.id,
    required this.name,
    required this.filePath,
  }) {
    audioPlayer = AudioPlayer();
  }

  Future<void> initialize() async {
    try {
      await audioPlayer.setAudioSource(AudioSource.file(filePath));
      audioPlayer.setVolume(volume);
      audioPlayer.setSpeed(1.0);
    } catch (e) {
      LoggerService.error('initializing audio track', e);
    }
  }

  void setVolume(double newVolume) {
    volume = newVolume.clamp(0.0, 1.0);
    if (!isMuted) {
      audioPlayer.setVolume(volume);
    }
  }

  void setPan(double newPan) {
    pan = newPan.clamp(-1.0, 1.0);
    // Note: just_audio doesn't have direct pan support
    // This would need to be implemented using audio_service
    // or a more advanced audio plugin
  }

  void mute() {
    isMuted = true;
    audioPlayer.setVolume(0.0);
  }

  void unmute() {
    isMuted = false;
    audioPlayer.setVolume(volume);
  }

  Future<void> dispose() async {
    await audioPlayer.dispose();
  }
}

class AudioMixerService {
  static final AudioMixerService _instance = AudioMixerService._internal();

  final Map<String, AudioTrack> _tracks = {};
  bool _isPlaying = false;
  Duration _currentPlaybackPosition = Duration.zero;
  final List<void Function()> _playbackListeners = [];

  factory AudioMixerService() {
    return _instance;
  }

  AudioMixerService._internal();

  // ===================== TRACK MANAGEMENT =====================

  Future<void> addTrack({
    required String trackId,
    required String trackName,
    required String filePath,
  }) async {
    if (_tracks.containsKey(trackId)) {
      await removeTrack(trackId);
    }

    final track = AudioTrack(
      id: trackId,
      name: trackName,
      filePath: filePath,
    );

    try {
      await track.initialize();
      _tracks[trackId] = track;
    } catch (e) {
      LoggerService.error('adding track', e);
      rethrow;
    }
  }

  Future<void> removeTrack(String trackId) async {
    final track = _tracks.remove(trackId);
    if (track != null) {
      await track.dispose();
    }
  }

  AudioTrack? getTrack(String trackId) {
    return _tracks[trackId];
  }

  List<AudioTrack> getAllTracks() {
    return _tracks.values.toList();
  }

  int getTrackCount() {
    return _tracks.length;
  }

  // ===================== VOLUME & PAN CONTROL =====================

  void setTrackVolume(String trackId, double volume) {
    final track = _tracks[trackId];
    if (track != null) {
      track.setVolume(volume);
    }
  }

  void setTrackPan(String trackId, double pan) {
    final track = _tracks[trackId];
    if (track != null) {
      track.setPan(pan);
    }
  }

  void muteTrack(String trackId) {
    final track = _tracks[trackId];
    if (track != null) {
      track.mute();
    }
  }

  void unmuteTrack(String trackId) {
    final track = _tracks[trackId];
    if (track != null) {
      track.unmute();
    }
  }

  void soloTrack(String trackId) {
    for (final track in _tracks.values) {
      if (track.id == trackId) {
        track.unmute();
      } else {
        track.mute();
      }
    }
  }

  void unsoloAll() {
    for (final track in _tracks.values) {
      track.unmute();
    }
  }

  // ===================== PLAYBACK CONTROL =====================

  Future<void> playAll() async {
    if (_isPlaying) return;

    _isPlaying = true;
    for (final track in _tracks.values) {
      try {
        await track.audioPlayer.play();
        track.isPlaying = true;
      } catch (e) {
        LoggerService.error('playing track ${track.id}', e);
      }
    }
    _notifyListeners();
  }

  Future<void> pauseAll() async {
    if (!_isPlaying) return;

    _isPlaying = false;
    for (final track in _tracks.values) {
      try {
        await track.audioPlayer.pause();
        track.isPlaying = false;
      } catch (e) {
        LoggerService.error('pausing track ${track.id}', e);
      }
    }
    _notifyListeners();
  }

  Future<void> stopAll() async {
    _isPlaying = false;
    for (final track in _tracks.values) {
      try {
        await track.audioPlayer.stop();
        track.isPlaying = false;
      } catch (e) {
        LoggerService.error('stopping track ${track.id}', e);
      }
    }
    _currentPlaybackPosition = Duration.zero;
    _notifyListeners();
  }

  Future<void> seekAll(Duration position) async {
    _currentPlaybackPosition = position;
    for (final track in _tracks.values) {
      try {
        await track.audioPlayer.seek(position);
      } catch (e) {
        LoggerService.error('seeking track ${track.id}', e);
      }
    }
  }

  // ===================== STATE MANAGEMENT =====================

  bool get isPlaying => _isPlaying;

  Duration get currentPosition => _currentPlaybackPosition;

  double getMasterVolume() {
    if (_tracks.isEmpty) return 1.0;

    double totalVolume = 0;
    int activeTracks = 0;

    for (final track in _tracks.values) {
      if (!track.isMuted) {
        totalVolume += track.volume;
        activeTracks++;
      }
    }

    return activeTracks > 0 ? totalVolume / activeTracks : 1.0;
  }

  Map<String, Map<String, dynamic>> getMixerState() {
    final state = <String, Map<String, dynamic>>{};
    for (final track in _tracks.values) {
      state[track.id] = {
        'name': track.name,
        'volume': track.volume,
        'pan': track.pan,
        'isMuted': track.isMuted,
        'isPlaying': track.isPlaying,
      };
    }
    return state;
  }

  // ===================== LISTENERS =====================

  void addPlaybackListener(void Function() listener) {
    _playbackListeners.add(listener);
  }

  void removePlaybackListener(void Function() listener) {
    _playbackListeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _playbackListeners) {
      listener();
    }
  }

  // ===================== CLEANUP =====================

  Future<void> dispose() async {
    await stopAll();
    for (final track in _tracks.values) {
      await track.dispose();
    }
    _tracks.clear();
    _playbackListeners.clear();
  }
}
