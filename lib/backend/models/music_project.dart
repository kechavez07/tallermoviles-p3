import 'package:uuid/uuid.dart';
import 'audio_track.dart';
import 'playback_state.dart';

/// Tipos de proyectos de música
enum ProjectType {
  /// Mezcla de loops
  loopMixer,

  /// Grabación multipista
  multiTrack,

  /// DJ set
  djSet,

  /// Otros
  other,
}

/// Representa un proyecto de música completo
class MusicProject {
  /// ID único del proyecto
  final String id;

  /// Nombre del proyecto
  final String name;

  /// Descripción
  final String? description;

  /// Tipo de proyecto
  final ProjectType projectType;

  /// Lista de pistas de audio
  final List<AudioTrack> tracks;

  /// BPM global del proyecto
  final double bpm;

  /// Time signature (numerador)
  final int timeSignatureNumerator;

  /// Time signature (denominador)
  final int timeSignatureDenominator;

  /// Duración total en milisegundos
  final int durationMs;

  /// Estado actual de reproducción del proyecto
  final PlaybackState playbackState;

  /// Si el proyecto está siendo reproducido
  final bool isPlaying;

  /// Volumen maestro (0.0 - 1.0)
  final double masterVolume;

  /// Metronomo habilitado
  final bool metronomeEnabled;

  /// Usuario propietario del proyecto
  final String? userId;

  /// URL en Firebase Firestore
  final String? firestoreDocPath;

  /// Timestamp de creación
  final DateTime createdAt;

  /// Timestamp de última actualización
  final DateTime updatedAt;

  /// Constructor
  MusicProject({
    String? id,
    required this.name,
    this.description,
    this.projectType = ProjectType.loopMixer,
    this.tracks = const [],
    this.bpm = 120.0,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    this.durationMs = 0,
    this.playbackState = const PlaybackState(status: PlaybackStatus.stopped),
    this.isPlaying = false,
    this.masterVolume = 1.0,
    this.metronomeEnabled = false,
    this.userId,
    this.firestoreDocPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Copia con cambios
  MusicProject copyWith({
    String? id,
    String? name,
    String? description,
    ProjectType? projectType,
    List<AudioTrack>? tracks,
    double? bpm,
    int? timeSignatureNumerator,
    int? timeSignatureDenominator,
    int? durationMs,
    PlaybackState? playbackState,
    bool? isPlaying,
    double? masterVolume,
    bool? metronomeEnabled,
    String? userId,
    String? firestoreDocPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MusicProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      projectType: projectType ?? this.projectType,
      tracks: tracks ?? this.tracks,
      bpm: bpm ?? this.bpm,
      timeSignatureNumerator: timeSignatureNumerator ?? this.timeSignatureNumerator,
      timeSignatureDenominator: timeSignatureDenominator ?? this.timeSignatureDenominator,
      durationMs: durationMs ?? this.durationMs,
      playbackState: playbackState ?? this.playbackState,
      isPlaying: isPlaying ?? this.isPlaying,
      masterVolume: masterVolume ?? this.masterVolume,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      userId: userId ?? this.userId,
      firestoreDocPath: firestoreDocPath ?? this.firestoreDocPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Agrega una pista
  MusicProject addTrack(AudioTrack track) {
    return copyWith(tracks: [...tracks, track]);
  }

  /// Remueve una pista por ID
  MusicProject removeTrack(String trackId) {
    return copyWith(tracks: tracks.where((t) => t.id != trackId).toList());
  }

  /// Actualiza una pista existente
  MusicProject updateTrack(AudioTrack track) {
    return copyWith(
      tracks: tracks.map((t) => t.id == track.id ? track : t).toList(),
    );
  }

  /// Obtiene volumen maestro considerando todas las pistas
  double getTotalMixVolume() {
    if (tracks.isEmpty) return masterVolume;
    double total = 0.0;
    for (final track in tracks) {
      if (track.isEnabled) {
        total += track.getEffectiveVolume();
      }
    }
    return (total / tracks.length) * masterVolume;
  }

  /// Cuántas pistas están activas
  int get activeTrackCount =>
      tracks.where((t) => t.isEnabled && !t.isMuted).length;

  /// Obtiene la duración máxima entre todas las pistas
  Duration getMaxDuration() {
    if (tracks.isEmpty) return Duration.zero;
    int maxDurationMs = 0;
    for (final track in tracks) {
      for (final loop in track.loops) {
        if (loop.durationMs > maxDurationMs) {
          maxDurationMs = loop.durationMs;
        }
      }
    }
    return Duration(milliseconds: maxDurationMs);
  }

  /// Convierte a Map para JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'projectType': projectType.toString(),
      'tracks': tracks.map((t) => t.toMap()).toList(),
      'bpm': bpm,
      'timeSignatureNumerator': timeSignatureNumerator,
      'timeSignatureDenominator': timeSignatureDenominator,
      'durationMs': durationMs,
      'masterVolume': masterVolume,
      'metronomeEnabled': metronomeEnabled,
      'userId': userId,
      'firestoreDocPath': firestoreDocPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crea desde Map
  factory MusicProject.fromMap(Map<String, dynamic> map) {
    return MusicProject(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      projectType: ProjectType.values.firstWhere(
        (e) => e.toString() == map['projectType'],
        orElse: () => ProjectType.loopMixer,
      ),
      tracks: (map['tracks'] as List<dynamic>?)
              ?.map((t) => AudioTrack.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      bpm: (map['bpm'] as num?)?.toDouble() ?? 120.0,
      timeSignatureNumerator: map['timeSignatureNumerator'] as int? ?? 4,
      timeSignatureDenominator: map['timeSignatureDenominator'] as int? ?? 4,
      durationMs: map['durationMs'] as int? ?? 0,
      masterVolume: (map['masterVolume'] as num?)?.toDouble() ?? 1.0,
      metronomeEnabled: map['metronomeEnabled'] as bool? ?? false,
      userId: map['userId'] as String?,
      firestoreDocPath: map['firestoreDocPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() =>
      'MusicProject(id: $id, name: $name, bpm: $bpm, tracks: ${tracks.length})';
}
