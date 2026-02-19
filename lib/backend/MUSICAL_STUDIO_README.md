# 🎵 Musical Studio Service - Documentación

## Descripción General

`MusicalStudioService` es un servicio integrado para construir un estudio musical colaborativo en Flutter. Proporciona:

- **Carga de Archivos**: Subida de pistas de audio a Cloudinary
- **Mezclador de Audio**: Control de volumen y pan para múltiples pistas
- **Almacenamiento Local**: SQLite para proyectos offline
- **Sincronización en Tiempo Real**: Colaboración con Firestore
- **Chat de Colaboradores**: Mensajes en time real
- **Gestión de Favoritos**: Marcación de samples favoritos

## Configuración

### 1. Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto:

```
CLOUDINARY_CLOUD_NAME=dsfazlofc
CLOUDINARY_API_KEY=375549546746736
CLOUDINARY_API_SECRET=2pvXZo07QeUjClYKqHgFBoMjoVI
CLOUDINARY_UPLOAD_PRESET=musical_studio
ENABLE_OFFLINE_MODE=true
```

### 2. Inicializar en main.dart

```dart
import 'package:estudio_musica_taller/backend/musical_studio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicio de estudio musical
  final studioService = MusicalStudioService();
  await studioService.initialize();
  
  runApp(const MyApp());
}
```

## Uso

### Crear un Proyecto

```dart
final studioService = MusicalStudioService();

final projectId = await studioService.createProject(
  projectName: 'Mi Primera Mezcla',
  userId: 'user123',
  description: 'Proyecto colaborativo de música',
);
```

### Subir Archivos de Audio

```dart
// Seleccionar archivo
final result = await FilePicker.platform.pickFiles(
  type: FileType.audio,
);

if (result != null) {
  final uploadResult = await studioService.uploadAudioToProject(
    projectId: projectId,
    userId: 'user123',
    audioFile: result.files.first,
    onProgress: (sent, total) {
      print('Progreso: ${(sent / total * 100).toStringAsFixed(0)}%');
    },
  );

  if (uploadResult['success']) {
    print('Track subido: ${uploadResult['trackId']}');
    print('URL: ${uploadResult['url']}');
  }
}
```

### Controlar el Mezclador

```dart
// Reproducir todas las pistas
await studioService.playMix();

// Control de volumen (0.0 - 1.0)
await studioService.setTrackVolume('trackId', 0.8);

// Control de pan (-1.0 izquierda, 0.0 centro, 1.0 derecha)
await studioService.setTrackPan('trackId', -0.5);

// Pausar
await studioService.pauseMix();

// Detener
await studioService.stopMix();
```

### Gestionar Favoritos

```dart
// Agregar a favoritos
await studioService.addToFavorites('sampleId', 'userId');

// Remover de favoritos
await studioService.removeFromFavorites('sampleId', 'userId');
```

### Chat de Colaboradores

```dart
// Enviar mensaje
await studioService.sendChatMessage(
  projectId: projectId,
  userId: 'user123',
  userName: 'Juan',
  message: 'Suena bien así',
);

// Escuchar mensajes (obtener stream)
final chatStream = studioService.realtimeSync.watchChatMessages(projectId);
chatStream.listen((snapshot) {
  for (final msg in snapshot.docs) {
    print('${msg['userName']}: ${msg['message']}');
  }
});
```

### Agregar Colaboradores

```dart
await studioService.addCollaborator(
  projectId: projectId,
  userId: 'collaborator123',
  userEmail: 'coll@example.com',
  role: 'editor', // o 'viewer'
);
```

### Sincronización Offline

```dart
// Cuando tenga conexión nuevamente
await studioService.syncPendingChanges();
```

## Arquitectura de Servicios

```
MusicalStudioService (Principal)
├── CloudinaryService (Carga de archivos)
├── LocalStorageService (SQLite)
├── AudioMixerService (Control de audio)
└── RealtimeSyncService (Firestore)
```

## Estructura de Base de Datos Local

### Tabla: projects
- `id`: ID único del proyecto
- `name`: Nombre del proyecto
- `userId`: Propietario del proyecto
- `description`: Descripción
- `createdAt`: Fecha de creación
- `updatedAt`: Última actualización
- `isSync`: Indica si está sincronizado

### Tabla: audio_samples
- `id`: ID único de la pista
- `projectId`: Proyecto al que pertenece
- `fileName`: Nombre del archivo
- `filePath`: Ruta local o URL en Cloudinary
- `volume`: Nivel de volumen (0.0-1.0)
- `pan`: Balance estéreo (-1.0 a 1.0)
- `cloudinaryId`: ID en Cloudinary
- `duration`: Duración en segundos
- `size`: Tamaño del archivo

### Tabla: favorite_samples
- `id`: ID único
- `sampleId`: Referencia a audio_samples
- `userId`: Usuario que marcó como favorito
- `addedAt`: Fecha de adición

### Tabla: settings
- Configuraciones personalizadas por usuario

### Tabla: sync_queue
- Cola de cambios pendientes para sincronizar

## Firestore Collections

```
projects/
├── {projectId}/
│   ├── tracks/
│   │   └── {trackId}
│   ├── collaborators/
│   │   └── {userId}
│   ├── chat/
│   │   └── {messageId}
│   └── offline_queue/
```

## Características Principales

### ✅ Almacenamiento Local con SQLite
- Crear y gestionar proyectos
- Guardar configuraciones
- Cola de sincronización

### ✅ Carga a Cloudinary
- Soporte para múltiples archivos
- Compresión de audio
- Progreso de descarga
- Transformaciones de URL

### ✅ Mezclador de Audio
- Control de volumen independiente
- Pan estéreo (izquierda/derecha)
- Reproducción sincronizada
- Solo/Mute de pistas

### ✅ Sincronización en Tiempo Real
- Actualizaciones instantáneas
- Chat integrado
- Gestión de colaboradores
- Soporte offline

## Ejemplo Completo

```dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:estudio_musica_taller/backend/musical_studio_service.dart';

class StudioScreen extends StatefulWidget {
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  late MusicalStudioService _studioService;
  String? _currentProjectId;

  @override
  void initState() {
    super.initState();
    _studioService = MusicalStudioService();
    _initializeStudio();
  }

  Future<void> _initializeStudio() async {
    await _studioService.initialize();
    _createNewProject();
  }

  Future<void> _createNewProject() async {
    _currentProjectId = await _studioService.createProject(
      projectName: 'Mi Mezcla',
      userId: 'user123',
    );
  }

  Future<void> _addAudioTrack() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && _currentProjectId != null) {
      final uploadResult = await _studioService.uploadAudioToProject(
        projectId: _currentProjectId!,
        userId: 'user123',
        audioFile: result.files.first,
      );

      if (uploadResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Track subido correctamente')),
        );
      }
    }
  }

  @override
  void dispose() {
    _studioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estudio Musical')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _addAudioTrack,
              child: Text('Agregar Pista'),
            ),
            ElevatedButton(
              onPressed: () => _studioService.playMix(),
              child: Text('Reproducir'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Notas de Seguridad

⚠️ **IMPORTANTE**: 
- Las credenciales de Cloudinary están en `.env` - **NO COMMITS A GIT**
- Usa variables de entorno en producción
- Implementa autenticación en Firestore
- Valida permisos de colaboradores

## Troubleshooting

### "Failed to initialize audio track"
- Verifica que el archivo de audio es válido
- Comprueba permisos de almacenamiento

### Cloudinary upload falla
- Verifica conexión a internet
- Valida credenciales en `.env`
- Comprueba límites de almacenamiento en Cloudinary

### SQLite errors
- Limpia la base de datos: `await localStorageService.resetDatabase()`
- Verifica permisos de almacenamiento

## API Reference

Ver documentación de sub-servicios:
- [CloudinaryService](./cloudinary_service.dart)
- [LocalStorageService](./local_storage_service.dart)
- [AudioMixerService](./audio/audio_mixer_service.dart)
- [RealtimeSyncService](./realtime_sync_service.dart)
