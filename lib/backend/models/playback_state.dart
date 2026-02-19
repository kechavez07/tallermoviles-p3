/// Estado de reproducción de audio
enum PlaybackStatus {
  /// Audio detenido
  stopped,

  /// Audio en pausa
  paused,

  /// Audio reproduciéndose
  playing,

  /// Error en reproducción
  error,
}

/// Clase que representa el estado actual de reproducción
class PlaybackState {
  /// Estado actual
  final PlaybackStatus status;

  /// Posición actual en milisegundos
  final Duration position;

  /// Duración total en milisegundos
  final Duration duration;

  /// Si está muted (silenciado)
  final bool isMuted;

  /// Velocidad de reproducción (1.0 = normal)
  final double playbackRate;

  /// Mensaje de error si aplica
  final String? errorMessage;

  const PlaybackState({
    required this.status,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isMuted = false,
    this.playbackRate = 1.0,
    this.errorMessage,
  });

  /// Copia con cambios
  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    bool? isMuted,
    double? playbackRate,
    String? errorMessage,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isMuted: isMuted ?? this.isMuted,
      playbackRate: playbackRate ?? this.playbackRate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'PlaybackState(status: $status, position: $position, duration: $duration, isMuted: $isMuted, playbackRate: $playbackRate)';
}
