import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';
import '../models/index.dart';

/// Estados de carga de archivo
enum UploadState {
  idle,
  selecting,
  validating,
  uploading,
  completed,
  error,
}

/// Información de progreso de carga
class UploadProgress {
  /// Estado actual
  final UploadState state;

  /// Nombre del archivo
  final String? fileName;

  /// Progreso de carga (0.0 a 1.0)
  final double progress;

  /// Bytes cargados
  final int? bytesTransferred;

  /// Bytes totales
  final int? totalBytes;

  /// Mensaje de error si aplica
  final String? errorMessage;

  /// URL final del archivo subido
  final String? downloadUrl;

  UploadProgress({
    required this.state,
    this.fileName,
    this.progress = 0.0,
    this.bytesTransferred,
    this.totalBytes,
    this.errorMessage,
    this.downloadUrl,
  });

  /// Copia con cambios
  UploadProgress copyWith({
    UploadState? state,
    String? fileName,
    double? progress,
    int? bytesTransferred,
    int? totalBytes,
    String? errorMessage,
    String? downloadUrl,
  }) {
    return UploadProgress(
      state: state ?? this.state,
      fileName: fileName ?? this.fileName,
      progress: progress ?? this.progress,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}

/// Gestor de carga de audio a Firebase Storage
class AudioUploadManager {
  /// Firebase Storage
  final FirebaseStorage firebaseStorage;

  /// Stream de progreso
  final BehaviorSubject<UploadProgress> uploadProgressSubject =
      BehaviorSubject<UploadProgress>.seeded(
        UploadProgress(state: UploadState.idle),
      );

  /// Extensiones de archivo permitidas
  static const List<String> allowedExtensions = ['mp3', 'wav', 'aac', 'flac', 'm4a'];

  /// Tamaño máximo de archivo (50 MB)
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  /// Ruta base en Firebase Storage
  static const String storageBasePath = 'audio_loops';

  /// Constructor
  AudioUploadManager({required this.firebaseStorage});

  /// Abre el selector de archivos
  Future<PlatformFile?> selectAudioFile() async {
    try {
      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.selecting,
      ));

      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
          state: UploadState.idle,
          fileName: file.name,
        ));
        return file;
      }

      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.idle,
      ));
      return null;
    } catch (e) {
      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.error,
        errorMessage: 'Error seleccionando archivo: $e',
      ));
      throw Exception('Error seleccionando archivo: $e');
    }
  }

  /// Valida un archivo de audio
  bool validateAudioFile(PlatformFile file) {
    // Verifica extensión
    final extension = file.extension?.toLowerCase() ?? '';
    if (!allowedExtensions.contains(extension)) {
      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.error,
        errorMessage: 'Formato no permitido. Usa: ${allowedExtensions.join(", ")}',
      ));
      return false;
    }

    // Verifica tamaño
    if (file.size > maxFileSizeBytes) {
      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.error,
        errorMessage: 'Archivo muy grande. Máximo: 50 MB',
      ));
      return false;
    }

    return true;
  }

  /// Sube un archivo a Firebase Storage
  Future<Loop> uploadAudioLoop(
    PlatformFile file, {
    required String trackId,
    required String category,
    double? bpm,
  }) async {
    try {
      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.validating,
        fileName: file.name,
      ));

      // Valida el archivo
      if (!validateAudioFile(file)) {
        throw Exception('Archivo no válido');
      }

      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.uploading,
        progress: 0.0,
      ));

      // Crea la ruta de almacenamiento
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${trackId}_${timestamp}_${file.name}';
      final storagePath = '$storageBasePath/$trackId/$fileName';

      // Obtiene el archivo local
      final localFile = File(file.path!);

      // Sube a Firebase Storage con tracking de progreso
      final uploadTask = firebaseStorage.ref(storagePath).putFile(localFile);

      // Escucha el progreso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
          progress: progress,
          bytesTransferred: snapshot.bytesTransferred,
          totalBytes: snapshot.totalBytes,
        ));
      });

      // Espera que se complete
      final result = await uploadTask;

      // Obtiene la URL de descarga
      final downloadUrl = await result.ref.getDownloadURL();

      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.completed,
        progress: 1.0,
        downloadUrl: downloadUrl,
      ));

      // Retorna un nuevo Loop con la URL
      return Loop(
        name: file.name,
        audioPath: file.path!,
        fileName: file.name,
        durationMs: 0, // Se calcularía analizando el archivo
        category: category,
        bpm: bpm,
        firebaseUrl: downloadUrl,
      );
    } catch (e) {
      uploadProgressSubject.add(uploadProgressSubject.value.copyWith(
        state: UploadState.error,
        errorMessage: 'Error cargando: $e',
      ));
      throw Exception('Error cargando: $e');
    }
  }

  /// Sube múltiples archivos
  Future<List<Loop>> uploadMultipleAudioLoops(
    List<PlatformFile> files, {
    required String trackId,
    required String category,
  }) async {
    final uploadedLoops = <Loop>[];

    for (final file in files) {
      try {
        final loop = await uploadAudioLoop(
          file,
          trackId: trackId,
          category: category,
        );
        uploadedLoops.add(loop);
      } catch (e) {
        // Continúa con el siguiente archivo
        continue;
      }
    }

    return uploadedLoops;
  }

  /// Elimina un audio de Firebase Storage
  Future<void> deleteAudioLoop(String storagePath) async {
    try {
      await firebaseStorage.ref(storagePath).delete();
    } catch (e) {
      throw Exception('Error eliminando archivo: $e');
    }
  }

  /// Reinicia el progreso
  void resetProgress() {
    uploadProgressSubject.add(UploadProgress(state: UploadState.idle));
  }

  /// Limpieza
  void dispose() {
    uploadProgressSubject.close();
  }
}

/// Provider global para gestor de upload
class AudioUploadProvider {
  static final AudioUploadManager _instance = AudioUploadManager(
    firebaseStorage: FirebaseStorage.instance,
  );

  static AudioUploadManager get instance => _instance;
}
