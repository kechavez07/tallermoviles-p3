import 'package:uuid/uuid.dart';

/// Representa un loop de audio dentro de una pista
class Loop {
  /// ID único del loop
  final String id;

  /// Nombre del loop
  final String name;

  /// URL o ruta del archivo de audio
  final String audioPath;

  /// Nombre del archivo
  final String fileName;

  /// Duración en milisegundos
  final int durationMs;

  /// Tag o categoría (drums, bass, melody, etc.)
  final String? category;

  /// BPM del loop (opcional)
  final double? bpm;

  /// Timestamp de creación
  final DateTime createdAt;

  /// URL en Firebase Storage (si está subida)
  final String? firebaseUrl;

  /// Constructor
  Loop({
    String? id,
    required this.name,
    required this.audioPath,
    required this.fileName,
    required this.durationMs,
    this.category,
    this.bpm,
    DateTime? createdAt,
    this.firebaseUrl,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Copia con cambios
  Loop copyWith({
    String? id,
    String? name,
    String? audioPath,
    String? fileName,
    int? durationMs,
    String? category,
    double? bpm,
    DateTime? createdAt,
    String? firebaseUrl,
  }) {
    return Loop(
      id: id ?? this.id,
      name: name ?? this.name,
      audioPath: audioPath ?? this.audioPath,
      fileName: fileName ?? this.fileName,
      durationMs: durationMs ?? this.durationMs,
      category: category ?? this.category,
      bpm: bpm ?? this.bpm,
      createdAt: createdAt ?? this.createdAt,
      firebaseUrl: firebaseUrl ?? this.firebaseUrl,
    );
  }

  /// Convierte a Map para JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'audioPath': audioPath,
      'fileName': fileName,
      'durationMs': durationMs,
      'category': category,
      'bpm': bpm,
      'createdAt': createdAt.toIso8601String(),
      'firebaseUrl': firebaseUrl,
    };
  }

  /// Crea desde Map
  factory Loop.fromMap(Map<String, dynamic> map) {
    return Loop(
      id: map['id'] as String,
      name: map['name'] as String,
      audioPath: map['audioPath'] as String,
      fileName: map['fileName'] as String,
      durationMs: map['durationMs'] as int,
      category: map['category'] as String?,
      bpm: map['bpm'] as double?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      firebaseUrl: map['firebaseUrl'] as String?,
    );
  }

  @override
  String toString() => 'Loop(id: $id, name: $name, duration: ${durationMs}ms)';
}
