import '/flutter_flow/flutter_flow_util.dart';
import '/backend/audio/audio_mixer_service.dart';
import 'mixer_widget.dart' show MixerWidget;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class MixerModel extends FlutterFlowModel<MixerWidget> {
  /// Audio Mixer Service
  late AudioMixerService audioMixerService;

  /// Track states (id -> volume)
  final Map<String, double> trackVolumes = {};
  final Map<String, double> trackPans = {};
  final Map<String, bool> trackMuted = {};
  
  /// Master volume
  double masterVolume = 1.0;
  bool isPlaying = false;
  
  /// Current tracks list for UI
  List<Map<String, dynamic>> displayTracks = [];

  @override
  void initState(BuildContext context) {
    audioMixerService = AudioMixerService();
  }

  /// Add track to mixer
  Future<void> addTrack({
    required String name,
    required String filePath,
  }) async {
    try {
      final trackId = const Uuid().v4();
      await audioMixerService.addTrack(
        trackId: trackId,
        trackName: name,
        filePath: filePath,
      );
      
      trackVolumes[trackId] = 1.0;
      trackPans[trackId] = 0.0;
      trackMuted[trackId] = false;
      
      displayTracks.add({
        'id': trackId,
        'name': name,
        'filePath': filePath,
      });
    } catch (e) {
      print('Error adding track: $e');
    }
  }

  /// Set track volume
  void setTrackVolume(String trackId, double volume) {
    trackVolumes[trackId] = volume;
    audioMixerService.setTrackVolume(trackId, volume);
  }

  /// Set track pan
  void setTrackPan(String trackId, double pan) {
    trackPans[trackId] = pan;
    audioMixerService.setTrackPan(trackId, pan);
  }

  /// Toggle mute
  void toggleMute(String trackId) {
    final isMuted = trackMuted[trackId] ?? false;
    trackMuted[trackId] = !isMuted;
    
    if (!isMuted) {
      audioMixerService.muteTrack(trackId);
    } else {
      audioMixerService.unmuteTrack(trackId);
    }
  }

  /// Play all tracks
  Future<void> playAll() async {
    isPlaying = true;
    for (var track in audioMixerService.getAllTracks()) {
      await track.audioPlayer.play();
    }
  }

  /// Pause all
  Future<void> pauseAll() async {
    isPlaying = false;
    for (var track in audioMixerService.getAllTracks()) {
      await track.audioPlayer.pause();
    }
  }

  /// Stop all
  Future<void> stopAll() async {
    isPlaying = false;
    await audioMixerService.stopAll();
  }

  /// Remove track
  Future<void> removeTrack(String trackId) async {
    await audioMixerService.removeTrack(trackId);
    trackVolumes.remove(trackId);
    trackPans.remove(trackId);
    trackMuted.remove(trackId);
    displayTracks.removeWhere((t) => t['id'] == trackId);
  }

  @override
  void dispose() {
    audioMixerService.stopAll();
  }
}
