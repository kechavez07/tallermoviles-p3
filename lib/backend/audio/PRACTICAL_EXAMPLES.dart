/// EJEMPLOS PRÁCTICOS DE USO DEL AUDIO ENGINE
/// 
/// Este archivo contiene ejemplos listos para copiar y pegar
/// de cómo usar la arquitectura de audio en diferentes escenarios.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/audio/index.dart';
import '../backend/models/index.dart';

// ==================== EJEMPLO 1: Widget de Reproductor Simple ====================

/// Un reproductor básico que muestra posición, duración y botones de control
class SimplePlayerWidget extends StatelessWidget {
  const SimplePlayerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        return StreamBuilder<PlaybackState>(
          stream: musicProject.player.playbackStateSubject.stream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? 
              const PlaybackState(status: PlaybackStatus.stopped);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mostrar canción actual
                Text(
                  musicProject.project.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 20),

                // Estado de reproducción
                Text(
                  state.status == PlaybackStatus.playing
                      ? 'Reproduciendo...'
                      : state.status == PlaybackStatus.paused
                          ? 'Pausado'
                          : 'Detenido',
                ),
                SizedBox(height: 20),

                // Barra de progreso
                StreamBuilder<Duration>(
                  stream: musicProject.player.currentPositionSubject.stream,
                  builder: (context, posSnapshot) {
                    final position = posSnapshot.data ?? Duration.zero;
                    final progress = musicProject.player.getProgress();

                    return Column(
                      children: [
                        LinearProgressIndicator(value: progress),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ProjectPlayer.formatDuration(position)),
                            Text(ProjectPlayer.formatDuration(
                              musicProject.player.projectDurationSubject.value,
                            )),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 30),

                // Botones de control
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous),
                      onPressed: () => musicProject.player.rewind(5),
                    ),
                    IconButton(
                      icon: Icon(state.status == PlaybackStatus.playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled),
                      iconSize: 56,
                      onPressed: () {
                        if (state.status == PlaybackStatus.playing) {
                          musicProject.pause();
                        } else {
                          musicProject.play();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next),
                      onPressed: () => musicProject.player.fastForward(5),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ==================== EJEMPLO 2: Widget de Control de Volumen ====================

/// Control de volumen maestro con display de % y controles de track individual
class VolumeControlWidget extends StatelessWidget {
  const VolumeControlWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Volumen maestro
                Text('Volumen Maestro',
                    style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: musicProject.player.audioEngine.masterVolume,
                        onChanged: (value) {
                          musicProject.setMasterVolume(value);
                        },
                        min: 0,
                        max: 1,
                      ),
                    ),
                    Icon(Icons.volume_up),
                    SizedBox(width: 8),
                    Text(
                      '${(musicProject.player.audioEngine.masterVolume * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Volumen por pista
                Text('Pistas',
                    style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                ...musicProject.project.tracks.map((track) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(track.name,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          child: Slider(
                            value: musicProject.mixer.getTrackVolume(track.id),
                            onChanged: (value) {
                              musicProject.mixer.setTrackVolume(track.id, value);
                            },
                            min: 0,
                            max: 1,
                          ),
                        ),
                        SizedBox(width: 40),
                        IconButton(
                          icon: Icon(
                            musicProject.mixer.isTrackMuted(track.id)
                                ? Icons.volume_off
                                : Icons.volume_up,
                          ),
                          onPressed: () {
                            musicProject.mixer.muteTrack(
                              track.id,
                              !musicProject.mixer.isTrackMuted(track.id),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== EJEMPLO 3: Agregar Pista Mediante Dialog ====================

/// Dialog para crear una nueva pista con nombre e instrumento
Future<void> showAddTrackDialog(BuildContext context) {
  final nameController = TextEditingController();
  final instrumentController = TextEditingController();
  String selectedColor = '#FF6B6B';

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Agregar Pista'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la pista',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: instrumentController,
              decoration: InputDecoration(
                labelText: 'Tipo de instrumento',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Selector de color
            Wrap(
              spacing: 8,
              children: [
                '#FF6B6B', // Rojo
                '#4ECDC4', // Turquesa
                '#45B7D1', // Azul
                '#FFA07A', // Naranja
                '#98D8C8', // Menta
              ].map((color) {
                return GestureDetector(
                  onTap: () => selectedColor = color,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${color.substring(1)}')),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color ? Colors.white : Colors.grey,
                        width: selectedColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            await context.read<MusicProjectNotifier>().addTrack(
              name: nameController.text,
              instrumentType: instrumentController.text,
              color: selectedColor,
            );
            Navigator.pop(context);
          },
          child: Text('Agregar'),
        ),
      ],
    ),
  );
}

// ==================== EJEMPLO 4: Upload de Audio ====================

/// Widget para subir un audio a Firebase Storage
class AudioUploadWidget extends StatelessWidget {
  const AudioUploadWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        return StreamBuilder<UploadProgress>(
          stream: musicProject.uploadManager.uploadProgressSubject.stream,
          builder: (context, snapshot) {
            final progress = snapshot.data ?? UploadProgress(
              state: UploadState.idle,
            );

            return Column(
              children: [
                if (progress.state == UploadState.idle)
                  ElevatedButton.icon(
                    icon: Icon(Icons.upload_file),
                    label: Text('Subir Audio'),
                    onPressed: () async {
                      final file =
                          await musicProject.uploadManager.selectAudioFile();
                      if (file != null && context.mounted) {
                        try {
                          final loop = await musicProject.uploadManager
                              .uploadAudioLoop(
                            file,
                            trackId: 'track_1',
                            category: 'loop',
                          );
                          if (context.mounted) {
                            await musicProject.addLoopToTrack('track_1', loop);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Audio subido exitosamente'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                if (progress.state == UploadState.uploading)
                  Column(
                    children: [
                      Text('Subiendo ${progress.fileName}...'),
                      SizedBox(height: 12),
                      LinearProgressIndicator(value: progress.progress),
                      SizedBox(height: 8),
                      Text(
                        '${(progress.progress * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                if (progress.state == UploadState.completed)
                  Text('✓ Upload completado',
                      style: TextStyle(color: Colors.green)),
                if (progress.state == UploadState.error)
                  Text('✗ Error: ${progress.errorMessage}',
                      style: TextStyle(color: Colors.red)),
              ],
            );
          },
        );
      },
    );
  }
}

// ==================== EJEMPLO 5: Visualizador de Estado ====================

/// Widget que muestra el estado completo del proyecto en tiempo real
class ProjectStatusWidget extends StatelessWidget {
  const ProjectStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        final mixerInfo = musicProject.mixer.getMixerInfo();

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado del Proyecto',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 16),
                _buildInfoRow('Nombre:', musicProject.project.name),
                _buildInfoRow('BPM:', '${musicProject.project.bpm}'),
                _buildInfoRow('Pistas:', '${musicProject.project.tracks.length}'),
                _buildInfoRow(
                  'Pistas activas:',
                  '${musicProject.project.activeTrackCount}',
                ),
                _buildInfoRow(
                  'Solo activo:',
                  mixerInfo.hasActiveSolo ? 'Sí' : 'No',
                ),
                _buildInfoRow(
                  'Volumen maestro:',
                  '${(mixerInfo.masterVolume * 100).toStringAsFixed(0)}%',
                ),
                SizedBox(height: 16),
                Text('Detalle de Pistas:',
                    style: Theme.of(context).textTheme.titleSmall),
                ...mixerInfo.trackMixes.map((trackMix) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(trackMix.trackName,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('Vol: ${(trackMix.volume * 100).toStringAsFixed(0)}%'),
                        SizedBox(width: 16),
                        if (trackMix.isMuted)
                          Chip(label: Text('Muted'), backgroundColor: Colors.red),
                        if (trackMix.isSolo)
                          Chip(label: Text('Solo'), backgroundColor: Colors.green),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

// ==================== EJEMPLO 6: Crossfader ====================

/// Widget que permite usar un crossfader entre dos pistas
class CrossfaderWidget extends StatefulWidget {
  const CrossfaderWidget({Key? key}) : super(key: key);

  @override
  State<CrossfaderWidget> createState() => _CrossfaderWidgetState();
}

class _CrossfaderWidgetState extends State<CrossfaderWidget> {
  double _crossfadeValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        final tracks = musicProject.project.tracks;
        if (tracks.length < 2) {
          return Text('Se necesitan al menos 2 pistas para usar crossfader');
        }

        return Column(
          children: [
            Text('Crossfader entre ${tracks[0].name} y ${tracks[1].name}'),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(tracks[0].name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _crossfadeValue < 0.5 ? Colors.blue : Colors.grey,
                      )),
                ),
                Expanded(
                  child: Slider(
                    value: _crossfadeValue,
                    onChanged: (value) {
                      setState(() => _crossfadeValue = value);
                      musicProject.mixer.crossfade(
                        tracks[0].id,
                        tracks[1].id,
                        value,
                      );
                    },
                    min: 0,
                    max: 1,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(tracks[1].name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _crossfadeValue > 0.5 ? Colors.blue : Colors.grey,
                      )),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ==================== EJEMPLO 7: Visualización de Sincronización ====================

/// Widget que muestra el estado de sincronización de pistas
class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        final synchronizer = musicProject.player.synchronizer;

        return StreamBuilder<bool>(
          stream: synchronizer.isOutOfSyncSubject.stream,
          builder: (context, snapshot) {
            final isOutOfSync = snapshot.data ?? false;

            return Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isOutOfSync ? Colors.orange[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOutOfSync ? Icons.warning : Icons.check_circle,
                        color: isOutOfSync ? Colors.orange : Colors.green,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isOutOfSync ? 'Desincronizado' : 'Sincronizado',
                        style: TextStyle(
                          color: isOutOfSync ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rango: ${synchronizer.getSyncRange().inMilliseconds}ms',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
