/// GUÍA DE INTEGRACIÓN: Conectar UI del Mixer con Lógica de Audio
/// 
/// Este archivo documenta cómo integrar los controles del mixer UI
/// con los servicios de audio backend.

import 'package:flutter/material.dart';
import '../models/index.dart';
import 'audio_providers.dart';

/// [PASO 1] Actualizar MixerModel para usar los servicios de audio
/// 
/// Reemplaza el MixerModel existente en: lib/main/mixer/mixer_model.dart
/// 
/// ```dart
/// import '/flutter_flow/flutter_flow_util.dart';
/// import '/backend/audio/index.dart';
/// import '/backend/models/index.dart';
/// import 'mixer_widget.dart' show MixerWidget;
/// import 'package:flutter/material.dart';
/// import 'package:provider/provider.dart';
/// 
/// class MixerModel extends FlutterFlowModel<MixerWidget> {
///   /// Referencia al notifier del proyecto de música
///   late MusicProjectNotifier musicProjectNotifier;
///   
///   /// Mapeo de pistas a sus valores de volumen en sliders
///   Map<String, double> trackVolumes = {};
///   
///   @override
///   void initState(BuildContext context) {
///     // Se inicializa en el widget
///   }
///   
///   @override
///   void dispose() {
///     // Limpieza si es necesaria
///   }
/// }
/// ```

/// [PASO 2] Actualizar MixerWidget para usar Provider y mostrar pistas dinámicas
/// 
/// En el widget, reemplaza los controles estáticos con dinámicos:
/// 
/// ```dart
/// class _MixerWidgetState extends State<MixerWidget> {
///   late MixerModel _model;
///   final scaffoldKey = GlobalKey<ScaffoldState>();
/// 
///   @override
///   void initState() {
///     super.initState();
///     _model = createModel(context, () => MixerModel());
///     WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
///   }
/// 
///   @override
///   void dispose() {
///     _model.dispose();
///     super.dispose();
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Consumer<MusicProjectNotifier>(
///       builder: (context, musicProject, _) {
///         return Scaffold(
///           key: scaffoldKey,
///           backgroundColor: Color(0xFF0A0A0A),
///           body: SafeArea(
///             child: Column(
///               children: [
///                 // Header con información del proyecto
///                 _buildHeader(musicProject),
///                 
///                 // Lista de pistas
///                 Expanded(
///                   child: ListView.builder(
///                     itemCount: musicProject.project.tracks.length,
///                     itemBuilder: (context, index) {
///                       final track = musicProject.project.tracks[index];
///                       return _buildTrackControl(context, track, musicProject);
///                     },
///                   ),
///                 ),
///                 
///                 // Controles globales
///                 _buildGlobalControls(context, musicProject),
///               ],
///             ),
///           ),
///         );
///       },
///     );
///   }
/// }
/// ```

/// [PASO 3] Componentes helper para construir controles
/// 
/// Widget para un control de pista individual:

class TrackControlWidget extends StatelessWidget {
  final AudioTrack track;
  final MusicProjectNotifier musicProject;
  final VoidCallback onRemove;

  const TrackControlWidget({
    Key? key,
    required this.track,
    required this.musicProject,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Color(0xFF00D4FF), width: 2.0),
      ),
      child: Column(
        children: [
          // Nombre y botones de control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      track.instrumentType,
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón Mute
              IconButton(
                icon: Icon(
                  musicProject.mixer.isTrackMuted(track.id)
                      ? Icons.volume_off
                      : Icons.volume_up,
                  color: musicProject.mixer.isTrackMuted(track.id)
                      ? Colors.red
                      : Color(0xFF00D4FF),
                ),
                onPressed: () {
                  musicProject.mixer.muteTrack(
                    track.id,
                    !musicProject.mixer.isTrackMuted(track.id),
                  );
                },
              ),
              // Botón Solo
              IconButton(
                icon: Icon(
                  Icons.headphones,
                  color: musicProject.mixer.isTrackSolo(track.id)
                      ? Colors.green
                      : Color(0xFF888888),
                ),
                onPressed: () {
                  musicProject.mixer.setTrackSolo(
                    track.id,
                    !musicProject.mixer.isTrackSolo(track.id),
                  );
                },
              ),
              // Botón Eliminar
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onRemove,
              ),
            ],
          ),
          SizedBox(height: 12.0),
          
          // Slider de volumen
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Volumen',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12.0),
                  ),
                  Text(
                    '${(musicProject.mixer.getTrackVolume(track.id) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12.0),
                  ),
                ],
              ),
              Slider(
                value: musicProject.mixer.getTrackVolume(track.id),
                onChanged: (value) {
                  musicProject.mixer.setTrackVolume(track.id, value);
                },
                min: 0.0,
                max: 1.0,
                activeColor: Color(0xFF00D4FF),
                inactiveColor: Color(0xFF444444),
              ),
            ],
          ),
          SizedBox(height: 12.0),
          
          // Slider de pan
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pan',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12.0),
                  ),
                  Text(
                    _panLabel(musicProject.mixer.getTrackPan(track.id)),
                    style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12.0),
                  ),
                ],
              ),
              Slider(
                value: musicProject.mixer.getTrackPan(track.id),
                onChanged: (value) {
                  musicProject.mixer.setTrackPan(track.id, value);
                },
                min: -1.0,
                max: 1.0,
                activeColor: Color(0xFF00D4FF),
                inactiveColor: Color(0xFF444444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _panLabel(double pan) {
    if (pan < -0.1) return 'Izq';
    if (pan > 0.1) return 'Der';
    return 'Centro';
  }
}

/// Widget para controles maestros
class MasterControlsWidget extends StatelessWidget {
  final MusicProjectNotifier musicProject;
  final VoidCallback onPlayPressed;
  final VoidCallback onPausePressed;
  final VoidCallback onStopPressed;

  const MasterControlsWidget({
    Key? key,
    required this.musicProject,
    required this.onPlayPressed,
    required this.onPausePressed,
    required this.onStopPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF00D4FF), width: 2.0)),
      ),
      child: Column(
        children: [
          // BPM Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BPM: ${musicProject.project.bpm.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: 100.0,
                child: Slider(
                  value: musicProject.project.bpm,
                  onChanged: (value) {
                    musicProject.setBPM(value);
                  },
                  min: 30.0,
                  max: 300.0,
                  activeColor: Color(0xFF00D4FF),
                  inactiveColor: Color(0xFF444444),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.0),
          
          // Master Volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Volumen Maestro',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(musicProject.player.audioEngine.masterVolume * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12.0),
              ),
            ],
          ),
          Slider(
            value: musicProject.player.audioEngine.masterVolume,
            onChanged: (value) {
              musicProject.setMasterVolume(value);
            },
            min: 0.0,
            max: 1.0,
            activeColor: Color(0xFF00D4FF),
            inactiveColor: Color(0xFF444444),
          ),
          SizedBox(height: 16.0),
          
          // Botones de control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: onPlayPressed,
                icon: Icon(Icons.play_arrow),
                label: Text('Reproducir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onPausePressed,
                icon: Icon(Icons.pause),
                label: Text('Pausa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onStopPressed,
                icon: Icon(Icons.stop),
                label: Text('Detener'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
