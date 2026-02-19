import 'package:uuid/uuid.dart';
import 'loop.dart';
import 'playback_state.dart';

/// Representa una pista de audio en el mixer
class AudioTrack {
  /// ID único de la pista
  final String id;

  /// Nombre de la pista
  final String name;

  /// Volumen (0.0 - 1.0)
  final double volume;

  /// Si está silenciada
  final bool isMuted;

  /// Si solo esta pista se está reproduciendo
  final bool isSolo;

  /// Pan (balance) izquierda-derecha (-1.0 a 1.0)
  final double pan;

  /// Color de identificación (hex)
  final String color;

  /// Lista de loops en esta pista
  final List<Loop> loops;

  /// Estado actual de reproducción
  final PlaybackState playbackState;

  /// Índice del loop actual siendo reproducido
  final int? currentLoopIndex;

  /// Si está habilitada para reproducción
  final bool isEnabled;

  /// Nombre del instrumento o tipo
  final String instrumentType;

  /// Timestamp de creación
  final DateTime createdAt;

  /// Constructor
  AudioTrack({
    String? id,
    required this.name,
    this.volume = 1.0,
    this.isMuted = false,
    this.isSolo = false,
    this.pan = 0.0,
    required this.color,
    this.loops = const [],
    this.playbackState = const PlaybackState(status: PlaybackStatus.stopped),
    this.currentLoopIndex,
    this.isEnabled = true,
    required this.instrumentType,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Copia con cambios
  AudioTrack copyWith({
    String? id,
    String? name,
    double? volume,
    bool? isMuted,
    bool? isSolo,
    double? pan,
    String? color,
    List<Loop>? loops,
    PlaybackState? playbackState,
    int? currentLoopIndex,
    bool? isEnabled,
    String? instrumentType,
    DateTime? createdAt,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      pan: pan ?? this.pan,
      color: color ?? this.color,
      loops: loops ?? this.loops,
      playbackState: playbackState ?? this.playbackState,
      currentLoopIndex: currentLoopIndex ?? this.currentLoopIndex,
      isEnabled: isEnabled ?? this.isEnabled,
      instrumentType: instrumentType ?? this.instrumentType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Agrega un loop a la pista
  AudioTrack addLoop(Loop loop) {
    return copyWith(loops: [...loops, loop]);
  }

  /// Remueve un loop por ID
  AudioTrack removeLoop(String loopId) {
    return copyWith(loops: loops.where((l) => l.id != loopId).toList());
  }

  /// Obtiene volumen considerando si está muted
  double getEffectiveVolume() {
    return isMuted ? 0.0 : volume;
  }

  /// Convierte a Map para JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'volume': volume,
      'isMuted': isMuted,
      'isSolo': isSolo,
      'pan': pan,
      'color': color,
      'loops': loops.map((l) => l.toMap()).toList(),
      'currentLoopIndex': currentLoopIndex,
      'isEnabled': isEnabled,
      'instrumentType': instrumentType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Crea desde Map
  factory AudioTrack.fromMap(Map<String, dynamic> map) {
    return AudioTrack(
      id: map['id'] as String,
      name: map['name'] as String,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: map['isMuted'] as bool? ?? false,
      isSolo: map['isSolo'] as bool? ?? false,
      pan: (map['pan'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] as String,
      loops: (map['loops'] as List<dynamic>?)
              ?.map((l) => Loop.fromMap(l as Map<String, dynamic>))
              .toList() ??
          [],
      currentLoopIndex: map['currentLoopIndex'] as int?,
      isEnabled: map['isEnabled'] as bool? ?? true,
      instrumentType: map['instrumentType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  String toString() =>
      'AudioTrack(id: $id, name: $name, volume: $volume, loops: ${loops.length})';
}
