import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/musical_studio_service.dart';
import '/backend/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'mixer_model.dart';
export 'mixer_model.dart';

class MixerWidget extends StatefulWidget {
  const MixerWidget({super.key});

  static String routeName = 'mixer';
  static String routePath = '/mixer';

  @override
  State<MixerWidget> createState() => _MixerWidgetState();
}

class _MixerWidgetState extends State<MixerWidget> {
  late MixerModel _model;
  late MusicalStudioService _studioService;
  late LocalStorageService _localStorageService;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentProjectId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MixerModel());
    _studioService = MusicalStudioService();
    _localStorageService = LocalStorageService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _studioService.initialize();
    // Create or load default project
    _currentProjectId = await _studioService.createProject(
      projectName: 'Mi Estudio Musical',
      userId: 'user_demo',
      description: 'Proyecto de estudio musical',
    );
    setState(() {});
  }

  Future<void> _selectAndAddAudio() async {
    if (_currentProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor espera a que cargue el proyecto')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Upload to cloud
        final uploadResult = await _studioService.uploadAudioToProject(
          projectId: _currentProjectId!,
          userId: 'user_demo',
          audioFile: file,
          onProgress: (sent, total) {
            print('Progreso: ${(sent / total * 100).toStringAsFixed(0)}%');
          },
        );

        if (uploadResult['success']) {
          // Add to mixer
          await _model.addTrack(
            name: file.name,
            filePath: uploadResult['url'],
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Track: ${file.name} agregado ✓'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        } else {
          throw Exception(uploadResult['error'] ?? 'Error subiendo archivo');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF0A0A0A),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    begin: AlignmentDirectional(1.0, 0.0),
                    end: AlignmentDirectional(-1.0, 0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estudio Musical',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Color(0xFF00D4FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Tracks: ${_model.displayTracks.length}',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Manrope',
                                    color: Color(0xFF7F8C8D),
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _model.isPlaying
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _model.isPlaying
                                ? Icons.play_arrow
                                : Icons.pause,
                            color: _model.isPlaying ? Colors.green : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tracks List
              Expanded(
                child: _model.displayTracks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.music_note,
                                size: 64, color: Colors.grey[600]),
                            SizedBox(height: 16),
                            Text(
                              'No hay tracks agregados',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Presiona + para agregar pistas',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ..._model.displayTracks.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final track = entry.value;
                              final trackId = track['id'] as String;

                              return _buildTrackControl(
                                context,
                                trackId,
                                track['name'],
                                idx,
                              );
                            }).toList(),
                            SizedBox(height: 24),
                            _buildMasterControls(context),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _selectAndAddAudio,
          backgroundColor: Color(0xFF00D4FF),
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            _isLoading ? 'Cargando...' : 'Agregar Pista',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackControl(
    BuildContext context,
    String trackId,
    String trackName,
    int index,
  ) {
    final isMuted = _model.trackMuted[trackId] ?? false;
    final volume = _model.trackVolumes[trackId] ?? 1.0;
    final pan = _model.trackPans[trackId] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1A252F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF00D4FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Track ${index + 1}: $trackName',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _model.removeTrack(trackId),
                    child: Text('Eliminar'),
                  ),
                ],
                child: Icon(Icons.more_vert, color: Color(0xFF00D4FF)),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Volume Control
          Row(
            children: [
              Icon(
                Icons.volume_up,
                color: Color(0xFF00D4FF),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Color(0xFF00D4FF),
                  inactiveColor: Colors.grey[700],
                  onChanged: (v) {
                    _model.setTrackVolume(trackId, v);
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${(volume * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Pan Control
          Row(
            children: [
              Icon(
                Icons.balance,
                color: Color(0xFF00D4FF),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: pan,
                  min: -1.0,
                  max: 1.0,
                  activeColor: Color(0xFF00D4FF),
                  inactiveColor: Colors.grey[700],
                  onChanged: (v) {
                    _model.setTrackPan(trackId, v);
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 8),
              Text(
                pan > 0 ? 'R' : pan < 0 ? 'L' : 'C',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Mute Button
          Row(
            children: [
              IconButton(
                onPressed: () {
                  _model.toggleMute(trackId);
                  setState(() {});
                },
                icon: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  color: isMuted ? Colors.red : Color(0xFF00D4FF),
                  size: 20,
                ),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              SizedBox(width: 8),
              Text(
                isMuted ? 'Silenciado' : 'Activo',
                style: TextStyle(
                  color: isMuted ? Colors.red : Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasterControls(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control Maestro',
            style: TextStyle(
              color: Color(0xFF00D4FF),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          // Master Volume
          Row(
            children: [
              Icon(Icons.volume_up, color: Color(0xFF00D4FF)),
              SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _model.masterVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Color(0xFF00D4FF),
                  onChanged: (v) {
                    _model.masterVolume = v;
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${(_model.masterVolume * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey[300], fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Play/Pause/Stop Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.play_arrow,
                label: 'Play',
                color: Colors.green,
                onPressed: () async {
                  await _model.playAll();
                  setState(() {});
                },
              ),
              _buildControlButton(
                icon: Icons.pause,
                label: 'Pause',
                color: Colors.orange,
                onPressed: () async {
                  await _model.pauseAll();
                  setState(() {});
                },
              ),
              _buildControlButton(
                icon: Icons.stop,
                label: 'Stop',
                color: Colors.red,
                onPressed: () async {
                  await _model.stopAll();
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          mini: true,
          backgroundColor: color.withOpacity(0.2),
          onPressed: onPressed,
          child: Icon(icon, color: color),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 12)),
      ],
    );
  }
}
