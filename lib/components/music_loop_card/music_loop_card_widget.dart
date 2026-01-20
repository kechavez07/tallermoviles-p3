import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '/backend/backend.dart';
import '/backend/cloudinary_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'music_loop_card_model.dart';
export 'music_loop_card_model.dart';

class MusicLoopCardWidget extends StatefulWidget {
  const MusicLoopCardWidget({
    super.key,
    required this.musicLoop,
  });

  final MusicLoopRecord musicLoop;

  @override
  State<MusicLoopCardWidget> createState() => _MusicLoopCardWidgetState();
}

class _MusicLoopCardWidgetState extends State<MusicLoopCardWidget> {
  late MusicLoopCardModel _model;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MusicLoopCardModel());

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _isLoading = true;
        });
        await _audioPlayer.play(UrlSource(widget.musicLoop.cloudinaryUrl));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _downloadLoop() async {
    try {
      final url = Uri.parse(widget.musicLoop.cloudinaryUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading: $e')),
        );
      }
    }
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Play/Pause button
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).info,
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: FlutterFlowTheme.of(context).info,
                      ),
                      onPressed: _togglePlayPause,
                    ),
            ),
            const SizedBox(width: 12),

            // Loop info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.musicLoop.title,
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (widget.musicLoop.description.isNotEmpty)
                    Text(
                      widget.musicLoop.description,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(widget.musicLoop.duration),
                        style: FlutterFlowTheme.of(context).labelSmall,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.storage,
                        size: 14,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatFileSize(widget.musicLoop.fileSize),
                        style: FlutterFlowTheme.of(context).labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Download button
            IconButton(
              icon: Icon(
                Icons.download,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
              onPressed: _downloadLoop,
            ),
          ],
        ),
      ),
    );
  }
}
