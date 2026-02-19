import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../backend/musical_studio_service.dart';

/// Ejemplo de uso del servicio de estudio musical
/// Este widget muestra cómo:
/// - Crear un proyecto
/// - Subir pistas
/// - Controlar el mezclador
/// - Gestionar colaboradores

class MusicalStudioExample extends StatefulWidget {
  @override
  State<MusicalStudioExample> createState() => _MusicalStudioExampleState();
}

class _MusicalStudioExampleState extends State<MusicalStudioExample> {
  late MusicalStudioService _studioService;
  String? _currentProjectId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _tracks = [];
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initStudio();
  }

  Future<void> _initStudio() async {
    _studioService = MusicalStudioService();
    await _studioService.initialize();
    
    // Crear proyecto de ejemplo
    _createProject();
  }

  Future<void> _createProject() async {
    try {
      _currentProjectId = await _studioService.createProject(
        projectName: 'Mi Primer Estudio',
        userId: 'user_demo_123',
        description: 'Proyecto de demostración del estudio musical',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proyecto creado: $_currentProjectId')),
      );
    } catch (e) {
      _showError('Error creando proyecto: $e');
    }
  }

  Future<void> _selectAndUploadAudio() async {
    if (_currentProjectId == null) {
      _showError('Primero debes crear un proyecto');
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

        final uploadResult = await _studioService.uploadAudioToProject(
          projectId: _currentProjectId!,
          userId: 'user_demo_123',
          audioFile: file,
          onProgress: (sent, total) {
            print('Subida: ${(sent / total * 100).toStringAsFixed(0)}%');
          },
        );

        if (uploadResult['success']) {
          setState(() {
            _tracks.add({
              'id': uploadResult['trackId'],
              'name': file.name,
              'url': uploadResult['url'],
              'volume': 1.0,
              'pan': 0.0,
              'isMuted': false,
            });
          });

          _showSuccess('Pista subida: ${file.name}');
        } else {
          _showError(uploadResult['error'] ?? 'Error en subida');
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _studioService.pauseMix();
      } else {
        await _studioService.playMix();
      }
      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      _showError('Error en reproducción: $e');
    }
  }

  void _updateTrackVolume(int index, double volume) {
    final trackId = _tracks[index]['id'];
    _studioService.setTrackVolume(trackId, volume);
    
    setState(() {
      _tracks[index]['volume'] = volume;
    });
  }

  void _removeTrack(int index) async {
    try {
      if (_currentProjectId == null) return;

      final trackId = _tracks[index]['id'];
      await _studioService.removeTrackFromProject(
        projectId: _currentProjectId!,
        trackId: trackId,
      );

      setState(() {
        _tracks.removeAt(index);
      });

      _showSuccess('Pista eliminada');
    } catch (e) {
      _showError('Error eliminando pista: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _studioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Estudio Musical'),
        centerTitle: true,
      ),
      body: _currentProjectId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Información del Proyecto
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proyecto Actual',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('ID: $_currentProjectId'),
                            const SizedBox(height: 8),
                            Text('Pistas: ${_tracks.length}'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Botones de Control
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _selectAndUploadAudio,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Pista'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _togglePlayback,
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          label: Text(_isPlaying ? 'Pausar' : 'Reproducir'),
                        ),
                      ],
                    ),
                  ),

                  // Lista de Pistas
                  if (_tracks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pistas en Proyecto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._tracks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final track = entry.value;
                            return TrackCard(
                              track: track,
                              onVolumeChanged: (volume) =>
                                  _updateTrackVolume(index, volume),
                              onRemove: () => _removeTrack(index),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay pistas aún',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agrega pistas para comenzar a mezclar',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Widget para mostrar y controlar una pista individual
class TrackCard extends StatelessWidget {
  final Map<String, dynamic> track;
  final Function(double) onVolumeChanged;
  final VoidCallback onRemove;

  const TrackCard({
    required this.track,
    required this.onVolumeChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Volumen: ${(track['volume'] * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: track['volume'],
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: onVolumeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
