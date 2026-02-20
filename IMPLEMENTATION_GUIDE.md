# 🎵 Estudio Musical - Taller Móviles P3

## ✅ Estado Actual (Febrero 2026)

Este proyecto ahora es **completamente funcional**. Se han integrado todas las especificaciones requeridas:

### 🎛️ Componentes Implementados

#### 1. **Mixer - Estudio Musical Profesional** [`mixer_widget.dart`]
- ✅ Múltiples pistas de audio (agregar/eliminar tracks)
- ✅ Control de volumen por track (0-100%)
- ✅ Control de paneo estéreo (L/R/C)
- ✅ Funciones de mute/solo
- ✅ Control maestro de volumen
- ✅ Botones Play/Pause/Stop
- ✅ Upload de archivos de audio desde dispositivo
- ✅ Progreso de carga visual
- ✅ Integración con AudioMixerService

**Ruta:** `/mixer`

#### 2. **Biblioteca Musical - Gestión de Proyectos** [`musiclibrary1_widget.dart`]
- ✅ Crear nuevos proyectos musicales
- ✅ Listar proyectos existentes con vista de grid
- ✅ Editar información de proyectos
- ✅ Eliminar proyectos
- ✅ Ver fecha de creación
- ✅ Acceso directo al mixer por proyecto

**Ruta:** `/musiclibrary1`

#### 3. **Chat de Colaboradores - Tiempo Real** [`chat_page_widget.dart`]
- ✅ Chat sincronizado en Firestore
- ✅ Mensajes en tiempo real
- ✅ Avatares de usuarios
- ✅ Identificación automática de emisor
- ✅ Historial de mensajes
- ✅ Stream de Firestore para actualizaciones

**Ruta:** `/chatPage`

#### 4. **Player - Reproducción de Audio** [`player_widget.dart`]
- ✅ Visualización de pistas
- ✅ Control de reproducción
- ✅ Barra de progreso

**Ruta:** `/player`

#### 5. **Indicador de Estado Offline** [`offline_indicator.dart`]
- ✅ Detección automática de conexión
- ✅ Indicador visual cuando no hay conexión
- ✅ Cola de sincronización visible

---

## 🗄️ Servicios Backend Integrados

### 1. **MusicalStudioService**
- Orquesta todos los servicios
- Crear/eliminar proyectos
- Upload de audio a Cloudinary
- Gestión de colaboradores

```dart
final studioService = MusicalStudioService();
await studioService.initialize();

final projectId = await studioService.createProject(
  projectName: 'Mi Estudio',
  userId: 'user_123',
  description: 'Proyecto colaborativo',
);
```

### 2. **AudioMixerService**
- Control de múltiples pistas
- Volumen, pan, mute/solo
- Reproducción sincronizada

```dart
await mixer.addTrack(
  trackId: 'track_1',
  trackName: 'Drums',
  filePath: 'path/to/audio.mp3',
);

mixer.setTrackVolume('track_1', 0.8);
mixer.setTrackPan('track_1', -0.5); // Izquierda
```

### 3. **RealtimeSyncService**
- Sincronización en tiempo real con Firestore
- Chat de colaboradores
- Actualizaciones instantáneas de proyectos

```dart
await sync.watchProject(projectId);
await sync.sendChatMessage(
  projectId: projectId,
  userId: userId,
  userName: 'Juan',
  message: 'Suena bien así',
);
```

### 4. **LocalStorageService (SQLite)**
- Almacenamiento local de proyectos
- Caché de muestras de audio
- Cola de sincronización para offline

```dart
await localStorage.createProject(
  id: projectId,
  name: 'Mi Proyecto',
  userId: userId,
);

final projects = await localStorage.getUserProjects(userId);
```

### 5. **CloudinaryService**
- Upload de archivos de audio
- Download y gestión de recursos
- Metadatos de audio

```dart
final result = await cloudinary.uploadAudioFile(
  file: audioFile,
  projectId: projectId,
  onProgress: (sent, total) {
    print('${(sent/total*100).toStringAsFixed(0)}%');
  },
);
```

---

## 🚀 Cómo Usar

### 1. **Crear un Proyecto**
```
1. Ir a "Biblioteca Musical" (Musiclibrary)
2. Presionar botón "+Nuevo Proyecto"
3. Ingresar nombre y descripción
4. Presionar "Crear"
```

### 2. **Agregar Pistas de Audio**
```
1. Desde Biblioteca Musical, presionar "Editar" en un proyecto
2. En el Mixer, presionar "+Agregar Pista"
3. Seleccionar archivo de audio del dispositivo
4. El archivo se cargará a Cloudinary
5. La pista aparecerá en el control deslizante
```

### 3. **Mezclar Audio**
```
1. En el Mixer:
   - Usar sliders de volumen (0-100%)
   - Usar slider de paneo (L/C/R)
   - Presionar icono de volumen para silenciar
   - Usar botones Play/Pause/Stop para reproducir
```

### 4. **Chat de Colaboradores**
```
1. Desde cualquier página, acceder a Chat
2. Escribir mensaje en la caja de texto
3. Presionar botón de envío
4. Los mensajes aparecen en tiempo real para todos los colaboradores
```

### 5. **Modo Offline**
```
- La aplicación detecta automáticamente cuando no hay conexión
- Se muestra un banner naranja "Modo Offline"
- Los cambios se guardan localmente en SQLite
- Al recuperar conexión, se sincronizan automáticamente
```

---

## 📊 Estructura de Datos

### Projects (Firestore + SQLite)
```
{
  id: String,
  name: String,
  description: String,
  userId: String,
  createdAt: DateTime,
  updatedAt: DateTime,
  isSync: bool,  // Sincronizado con nube
}
```

### Audio Samples (SQLite)
```
{
  id: String,
  projectId: String,
  fileName: String,
  filePath: String,
  cloudinaryId: String,
  url: String,
  volume: double,  // 0.0 - 1.0
  pan: double,     // -1.0 a 1.0
  duration: double,
  size: int,
  isLocal: bool,
  createdAt: DateTime,
}
```

### Chat Messages (Firestore)
```
{
  userId: String,
  userName: String,
  message: String,
  timestamp: DateTime,
  avatar: String,
}
```

---

## 🔧 Configuración Necesaria

### Firebase
El proyecto ya está configurado. Los archivos de configuración están en:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

### Cloudinary
Credenciales configuradas en `lib/backend/cloudinary_service.dart`:
- Cloud Name: `dsfazlofc`
- API Key: `375549546746736`
- Upload Preset: `musical_studio`

### SQLite
Base de datos creada automáticamente en:
- Android: `app_data/databases/musical_studio.db`
- iOS: `Documents/musical_studio.db`

---

## 📝 Especificaciones Cumplidas

| Requisito | Estado |
|-----------|--------|
| Pistas de audio múltiples | ✅ Implementado |
| Mezclador simple | ✅ Totalmente funcional |
| Chat de colaboradores | ✅ Tiempo real con Firestore |
| Firebase Storage para samples | ✅ Cloudinary integrado |
| Subir/descargar loops | ✅ Funcional |
| Sincronización tiempo real | ✅ Firestore + RealtimeSync |
| SQLite local | ✅ Proyectos y caché offline |
| Favoritos | ✅ En LocalStorageService |
| Configuraciones personalizadas | ✅ En Settings widget |

---

## 📹 Demostración

### Video 1: Diseño del Estudio (5 min)
1. Mostrar interfaz del Mixer
2. Agregar múltiples pistas
3. Demostrar controles de volumen y paneo
4. Mostrar controles maestros

### Video 2: Colaboración en Tiempo Real (3 min)
1. Abrir Chat de dos usuarios diferentes
2. Enviar mensajes
3. Ver sincronización instantánea
4. Mostrar avatares y marcas de hora

### Video 3: Trabajo Offline (3 min)
1. Desactivar conexión wifi
2. Ver indicador de "Modo Offline"
3. Crear proyecto en offline
4. Ver cola de sincronización
5. Reactivar conexión
6. Ver sincronización automática

### Video 4: Sincronización (1 min)
1. Mostrar cambios en offline
2. Activar conexión
3. Ver sincronización progresiva
4. Confirmar datos en Firestore

---

## 🔄 Flujo de Sincronización

```
Acción Offline
    ↓
Guardar en SQLite
    ↓
Cola de Sincronización
    ↓
Se recupera conexión
    ↓
Procesar cola
    ↓
Actualizar Firestore
    ↓
Actualizar UI
```

---

## 📱 Rutas Disponibles

| Ruta | Componente | Función |
|------|-----------|---------|
| `/mixer` | MixerWidget | Control principal de mezclado |
| `/musiclibrary1` | Musiclibrary1Widget | Gestión de proyectos |
| `/chatPage` | ChatPageWidget | Chat de colaboradores |
| `/player` | PlayerWidget | Reproducción de audio |
| `/settings` | SettingsWidget | Configuración |
| `/home` | HomeWidget | Página de inicio |

---

## ⚙️ Inicialización (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await initFirebase();
  await FlutterFlowTheme.initialize();
  
  // Inicializar servicios
  final studioService = MusicalStudioService();
  await studioService.initialize();
  
  // Inicializar estado global
  final appState = AppStateService();
  
  runApp(MyApp());
}
```

---

## 🐛 Troubleshooting

### Error: "Firebase no inicializado"
```dart
await initFirebase();
```

### Error: "SQLite database locked"
```dart
// Reiniciar la aplicación
// SQLite se auto-recupera
```

### Chat no sincroniza
```dart
// Verificar conexión
// Verificar reglas de Firestore:
// allow read, write: if request.auth != null;
```

### Audio no se reproduce
```dart
// Verificar que AudioMixerService está inicializado
// Verificar permisos de micrófono/audio en manifest
```

---

## 📚 Archivos Clave

```
lib/
├── backend/
│   ├── musical_studio_service.dart      (Orquestador principal)
│   ├── audio_mixer_service.dart         (Control de audio)
│   ├── realtime_sync_service.dart       (Sincronización)
│   ├── local_storage_service.dart       (SQLite)
│   ├── cloudinary_service.dart          (Upload de archivos)
│   └── app_state_service.dart           (Estado global)
├── main/
│   ├── mixer/                           (Mezclador)
│   ├── musiclibrary1/                   (Proyectos)
│   ├── chat_page/                       (Chat)
│   └── player/                          (Reproducción)
└── components/
    └── offline_indicator.dart           (Indicador offline)
```

---

## ✨ Características Futuras

- [ ] Exportar mezcla a archivo MP3
- [ ] Aplicar efectos de audio
- [ ] Grabar voces en tiempo real
- [ ] Compartir proyectos públicamente
- [ ] Historial de versiones
- [ ] Análisis de espectro visual

---

## 📄 Licencia

Este proyecto es parte del **Taller de Desarrollo Móvil P3**.

---

**Última actualización:** 20 de febrero de 2026
