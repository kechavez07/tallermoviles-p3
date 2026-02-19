import 'package:rxdart/rxdart.dart';
import '../models/index.dart';
import 'audio_engine.dart';

/// Gestor de mixer para control de volumen, mute, solo y crossfader
class AudioMixer {
  /// Motor de audio
  final AudioEngine audioEngine;

  /// Volumen de cada pista (por ID de pista)
  final BehaviorSubject<Map<String, double>> trackVolumesSubject =
      BehaviorSubject<Map<String, double>>.seeded({});

  /// Estado muted de cada pista
  final BehaviorSubject<Map<String, bool>> trackMutesSubject =
      BehaviorSubject<Map<String, bool>>.seeded({});

  /// Estado solo de cada pista
  final BehaviorSubject<Map<String, bool>> trackSolosSubject =
      BehaviorSubject<Map<String, bool>>.seeded({});

  /// Pan (balance) de cada pista (-1.0 a 1.0)
  final BehaviorSubject<Map<String, double>> trackPansSubject =
      BehaviorSubject<Map<String, double>>.seeded({});

  /// Si hay alguna pista en solo
  bool get hasActiveSolo => trackSolosSubject.value.values.any((v) => v);

  /// Constructor
  AudioMixer({required this.audioEngine}) {
    _initializeTrackControls();
  }

  /// Inicializa los controles para todas las pistas
  void _initializeTrackControls() {
    final volumes = <String, double>{};
    final mutes = <String, bool>{};
    final solos = <String, bool>{};
    final pans = <String, double>{};

    for (final track in audioEngine.currentProject.tracks) {
      volumes[track.id] = track.volume;
      mutes[track.id] = track.isMuted;
      solos[track.id] = track.isSolo;
      pans[track.id] = track.pan;
    }

    trackVolumesSubject.add(volumes);
    trackMutesSubject.add(mutes);
    trackSolosSubject.add(solos);
    trackPansSubject.add(pans);
  }

  /// Establece el volumen de una pista
  Future<void> setTrackVolume(String trackId, double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);

    // Actualiza el mapa
    final volumes = Map<String, double>.from(trackVolumesSubject.value);
    volumes[trackId] = clampedVolume;
    trackVolumesSubject.add(volumes);

    // Actualiza el audio
    await audioEngine.setTrackVolume(trackId, clampedVolume);

    // Actualiza el proyecto
    final project = audioEngine.currentProject;
    final updatedTracks = project.tracks.map((t) {
      if (t.id == trackId) {
        return t.copyWith(volume: clampedVolume);
      }
      return t;
    }).toList();
    audioEngine.updateProject(project.copyWith(tracks: updatedTracks));
  }

  /// Obtiene el volumen de una pista
  double getTrackVolume(String trackId) {
    return trackVolumesSubject.value[trackId] ?? 1.0;
  }

  /// Silencia una pista
  Future<void> muteTrack(String trackId, bool mute) async {
    // Actualiza el mapa
    final mutes = Map<String, bool>.from(trackMutesSubject.value);
    mutes[trackId] = mute;
    trackMutesSubject.add(mutes);

    if (mute) {
      await audioEngine.muteTrack(trackId);
    } else {
      final volume = getTrackVolume(trackId);
      await audioEngine.unmuteTrack(trackId, volume);
    }

    // Actualiza el proyecto
    final project = audioEngine.currentProject;
    final updatedTracks = project.tracks.map((t) {
      if (t.id == trackId) {
        return t.copyWith(isMuted: mute);
      }
      return t;
    }).toList();
    audioEngine.updateProject(project.copyWith(tracks: updatedTracks));
  }

  /// Obtiene si una pista está silenciada
  bool isTrackMuted(String trackId) {
    return trackMutesSubject.value[trackId] ?? false;
  }

  /// Activa/desactiva solo en una pista
  Future<void> setTrackSolo(String trackId, bool solo) async {
    // Actualiza el mapa
    final solos = Map<String, bool>.from(trackSolosSubject.value);
    solos[trackId] = solo;
    trackSolosSubject.add(solos);

    // Si activamos solo, silencia todas las demás
    if (solo && !hasActiveSolo) {
      for (final track in audioEngine.currentProject.tracks) {
        if (track.id != trackId) {
          await muteTrack(track.id, true);
        }
      }
    }
    // Si desactivamos solo, rehabilita las demás
    else if (!solo && !hasActiveSolo) {
      for (final track in audioEngine.currentProject.tracks) {
        if (track.id != trackId) {
          await muteTrack(track.id, false);
        }
      }
    }

    // Actualiza el proyecto
    final project = audioEngine.currentProject;
    final updatedTracks = project.tracks.map((t) {
      if (t.id == trackId) {
        return t.copyWith(isSolo: solo);
      }
      return t;
    }).toList();
    audioEngine.updateProject(project.copyWith(tracks: updatedTracks));
  }

  /// Obtiene si una pista tiene solo
  bool isTrackSolo(String trackId) {
    return trackSolosSubject.value[trackId] ?? false;
  }

  /// Establece el pan (balance) de una pista
  Future<void> setTrackPan(String trackId, double pan) async {
    final clampedPan = pan.clamp(-1.0, 1.0);

    // Actualiza el mapa
    final pans = Map<String, double>.from(trackPansSubject.value);
    pans[trackId] = clampedPan;
    trackPansSubject.add(pans);

    // Nota: en una implementación real, necesitarías usar audio_service o similar
    // para aplicar el pan a nivel de hardware/DSP
    // Por ahora solo guardamos el valor

    // Actualiza el proyecto
    final project = audioEngine.currentProject;
    final updatedTracks = project.tracks.map((t) {
      if (t.id == trackId) {
        return t.copyWith(pan: clampedPan);
      }
      return t;
    }).toList();
    audioEngine.updateProject(project.copyWith(tracks: updatedTracks));
  }

  /// Obtiene el pan de una pista
  double getTrackPan(String trackId) {
    return trackPansSubject.value[trackId] ?? 0.0;
  }

  /// Crossfader entre dos pistas (0.0 = pista 1, 1.0 = pista 2)
  Future<void> crossfade(String trackId1, String trackId2, double amount) async {
    final clamped = amount.clamp(0.0, 1.0);

    // Volume de la pista 1 disminuye (1.0 -> 0.0)
    final vol1 = 1.0 - clamped;
    // Volume de la pista 2 aumenta (0.0 -> 1.0)
    final vol2 = clamped;

    await setTrackVolume(trackId1, vol1);
    await setTrackVolume(trackId2, vol2);
  }

  /// Reestablece todos los controles a valores por defecto
  Future<void> resetAll() async {
    for (final track in audioEngine.currentProject.tracks) {
      await setTrackVolume(track.id, 1.0);
      await muteTrack(track.id, false);
      await setTrackSolo(track.id, false);
      await setTrackPan(track.id, 0.0);
    }
  }

  /// Obtiene el volumen maestro
  double getMasterVolume() {
    return audioEngine.masterVolume;
  }

  /// Establece el volumen maestro
  Future<void> setMasterVolume(double volume) async {
    await audioEngine.setMasterVolume(volume);
  }

  /// Obtiene información de mezcla para todas las pistas
  MixerInfo getMixerInfo() {
    final volumes = trackVolumesSubject.value;
    final mutes = trackMutesSubject.value;
    final solos = trackSolosSubject.value;
    final pans = trackPansSubject.value;

    final trackMixes = <TrackMix>[];
    for (final track in audioEngine.currentProject.tracks) {
      trackMixes.add(
        TrackMix(
          trackId: track.id,
          trackName: track.name,
          volume: volumes[track.id] ?? 1.0,
          isMuted: mutes[track.id] ?? false,
          isSolo: solos[track.id] ?? false,
          pan: pans[track.id] ?? 0.0,
        ),
      );
    }

    return MixerInfo(
      masterVolume: audioEngine.masterVolume,
      trackMixes: trackMixes,
      hasActiveSolo: hasActiveSolo,
    );
  }

  /// Limpieza
  void dispose() {
    trackVolumesSubject.close();
    trackMutesSubject.close();
    trackSolosSubject.close();
    trackPansSubject.close();
  }
}

/// Información de una pista en el mixer
class TrackMix {
  final String trackId;
  final String trackName;
  final double volume;
  final bool isMuted;
  final bool isSolo;
  final double pan;

  TrackMix({
    required this.trackId,
    required this.trackName,
    required this.volume,
    required this.isMuted,
    required this.isSolo,
    required this.pan,
  });
}

/// Información general del mixer
class MixerInfo {
  final double masterVolume;
  final List<TrackMix> trackMixes;
  final bool hasActiveSolo;

  MixerInfo({
    required this.masterVolume,
    required this.trackMixes,
    required this.hasActiveSolo,
  });
}
