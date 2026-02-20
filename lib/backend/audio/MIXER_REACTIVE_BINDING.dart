/// INTEGRACIÓN REACTIVA DEL MIXER - FIX 1.4
/// 
/// Este archivo contiene componentes y ejemplos para conectar el AudioMixer
/// al UI con binding reactivo en tiempo real.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './index.dart';
import '../models/index.dart';
import 'audio_providers.dart';
import 'audio_mixer.dart';

// ==================== MIXER TRACK SLIDER REACTIVO ====================

/// Slider reactivo que actualiza volumen en tiempo real
class ReactiveMixerSlider extends StatelessWidget {
  final String trackId;
  final String trackName;
  final Color color;

  const ReactiveMixerSlider({
    Key? key,
    required this.trackId,
    required this.trackName,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        // Escuchar cambios en el volumen de esta pista específica
        return StreamBuilder<Map<String, double>>(
          stream: musicProject.mixer.trackVolumesSubject.stream,
          builder: (context, snapshot) {
            final volumes = snapshot.data ?? {};
            final volume = volumes[trackId] ?? 1.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trackName, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${(volume * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                SizedBox(height: 8),
                Slider(
                  value: volume,
                  onChanged: (value) {
                    musicProject.mixer.setTrackVolume(trackId, value);
                  },
                  overlayColor: WidgetStateProperty.all(color.withOpacity(0.5)),
                  activeColor: color,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  onChangeEnd: (value) {
                    // Opcional: hacer algo cuando termine de mover
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ==================== MUTE BUTTON REACTIVO ====================

/// Botón de mute que refleja estado en tiempo real
class ReactiveMuteButton extends StatelessWidget {
  final String trackId;

  const ReactiveMuteButton({
    Key? key,
    required this.trackId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        // Escuchar cambios de mute para esta pista
        return StreamBuilder<Map<String, bool>>(
          stream: musicProject.mixer.trackMutesSubject.stream,
          builder: (context, snapshot) {
            final mutes = snapshot.data ?? {};
            final isMuted = mutes[trackId] ?? false;

            return IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: isMuted ? Colors.red : Colors.blue,
              ),
              onPressed: () {
                musicProject.mixer.muteTrack(trackId, !isMuted);
              },
              tooltip: isMuted ? 'Des-silenciar' : 'Silenciar',
            );
          },
        );
      },
    );
  }
}

// ==================== SOLO BUTTON REACTIVO ====================

/// Botón de solo que refleja estado en tiempo real
class ReactiveSoloButton extends StatelessWidget {
  final String trackId;

  const ReactiveSoloButton({
    Key? key,
    required this.trackId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        // Escuchar cambios de solo para esta pista
        return StreamBuilder<Map<String, bool>>(
          stream: musicProject.mixer.trackSolosSubject.stream,
          builder: (context, snapshot) {
            final solos = snapshot.data ?? {};
            final isSolo = solos[trackId] ?? false;

            return IconButton(
              icon: isSolo 
                ? const Icon(Icons.headphones, color: Colors.green)
                : const Icon(Icons.headphones_outlined, color: Colors.grey),
              onPressed: () {
                musicProject.mixer.setTrackSolo(trackId, !isSolo);
              },
              tooltip: isSolo ? 'Desactivar solo' : 'Activar solo',
            );
          },
        );
      },
    );
  }
}

// ==================== PAN SLIDER REACTIVO ====================

/// Slider de pan (balance L/R) reactivo
class ReactivePanSlider extends StatelessWidget {
  final String trackId;

  const ReactivePanSlider({
    Key? key,
    required this.trackId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        // Escuchar cambios de pan para esta pista
        return StreamBuilder<Map<String, double>>(
          stream: musicProject.mixer.trackPansSubject.stream,
          builder: (context, snapshot) {
            final pans = snapshot.data ?? {};
            final pan = pans[trackId] ?? 0.0;

            return Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_back_ios, size: 16),
                    Expanded(
                      child: Slider(
                        value: pan,
                        onChanged: (value) {
                          musicProject.mixer.setTrackPan(trackId, value);
                        },
                        min: -1.0,
                        max: 1.0,
                        divisions: 20,
                        label: pan == 0.0
                            ? 'Centro'
                            : pan < 0
                                ? 'Izq ${(-pan * 100).toStringAsFixed(0)}%'
                                : 'Der ${(pan * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
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

// ==================== MASTER VOLUME CONTROL REACTIVO ====================

/// Control reactivo de volumen maestro
class ReactiveMasterVolume extends StatelessWidget {
  const ReactiveMasterVolume({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        // El master volume se actualiza automáticamente
        // cuando cambia en audioEngine
        return StreamBuilder<MusicProject>(
          stream: musicProject.player.audioEngine.projectStateSubject.stream,
          builder: (context, snapshot) {
            final project = snapshot.data ?? musicProject.project;
            final masterVol = project.masterVolume;

            return Column(
              children: [
                Text('Master Volume',
                    style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: masterVol,
                        onChanged: (value) {
                          musicProject.setMasterVolume(value);
                        },
                        min: 0,
                        max: 1,
                        divisions: 100,
                      ),
                    ),
                    Icon(Icons.volume_up),
                    SizedBox(width: 12),
                    Text('${(masterVol * 100).toStringAsFixed(0)}%'),
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

// ==================== COMPUESTO: FILA DE CONTROL DE PISTA ====================

/// Widget completo de control para una pista del mixer
class MixerTrackControlRow extends StatelessWidget {
  final AudioTrack track;

  const MixerTrackControlRow({
    Key? key,
    required this.track,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre y controles rápidos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  track.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReactiveMuteButton(trackId: track.id),
                  SizedBox(width: 4),
                  ReactiveSoloButton(trackId: track.id),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Slider de volumen
          ReactiveMixerSlider(
            trackId: track.id,
            trackName: track.name,
            color: Color(int.parse('0xFF${track.color.substring(1)}')),
          ),
          SizedBox(height: 12),
          
          // Slider de pan
          ReactivePanSlider(trackId: track.id),
        ],
      ),
    );
  }
}

// ==================== MIXER COMPLETO REACTIVO ====================

/// Mixer completo con todos los controles reactivos
class ReactiveMixerPanel extends StatelessWidget {
  const ReactiveMixerPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        // Observar cambios en el proyecto
        return StreamBuilder<MusicProject>(
          stream: musicProject.player.audioEngine.projectStateSubject.stream,
          builder: (context, snapshot) {
            final project = snapshot.data ?? musicProject.project;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Master Volume
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: ReactiveMasterVolume(),
                  ),
                  Divider(),
                  
                  // Título de pistas
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Pistas (${project.tracks.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  
                  // Lista de tracks con control reactivo
                  ...project.tracks.map((track) {
                    return MixerTrackControlRow(track: track);
                  }).toList(),
                  
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== INDICADOR DE ESTADO DEL MIXER ====================

/// Widget que muestra información en tiempo real del mixer
class MixerStatusIndicator extends StatelessWidget {
  const MixerStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProjectNotifier>(
      builder: (context, musicProject, _) {
        return StreamBuilder<MixerInfo>(
          stream: Stream.periodic(Duration(milliseconds: 500), (_) {
            return musicProject.mixer.getMixerInfo();
          }),
          builder: (context, snapshot) {
            final info = snapshot.data;
            if (info == null) return SizedBox.shrink();

            return Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado del Mixer',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Master: ${(info.masterVolume * 100).toStringAsFixed(0)}%'),
                      Text('Pistas: ${info.trackMixes.length}'),
                      if (info.hasActiveSolo)
                        Chip(
                          label: Text('Solo ON', style: TextStyle(fontSize: 11)),
                          backgroundColor: Colors.orange,
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Mostrar pistas silenciadas
                  if (info.trackMixes.any((t) => t.isMuted))
                    Text(
                      'Silenciadas: ${info.trackMixes.where((t) => t.isMuted).map((t) => t.trackName).join(", ")}',
                      style: TextStyle(fontSize: 12, color: Colors.red),
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

// ==================== EJEMPLO: PÁGINA COMPLETA DE MIXER ====================

/// Página completa ejemplificando el uso del mixer reactivo
class MixerPageExample extends StatelessWidget {
  const MixerPageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mixer Reactivo'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Indicador de estado
          Padding(
            padding: EdgeInsets.all(16),
            child: MixerStatusIndicator(),
          ),
          Divider(),
          
          // Panel principal del mixer
          Expanded(
            child: ReactiveMixerPanel(),
          ),
        ],
      ),
    );
  }
}
