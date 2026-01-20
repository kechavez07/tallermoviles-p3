import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/cloudinary_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'upload_loop_dialog_model.dart';
export 'upload_loop_dialog_model.dart';

class UploadLoopDialogWidget extends StatefulWidget {
  const UploadLoopDialogWidget({super.key});

  @override
  State<UploadLoopDialogWidget> createState() => _UploadLoopDialogWidgetState();
}

class _UploadLoopDialogWidgetState extends State<UploadLoopDialogWidget> {
  late UploadLoopDialogModel _model;
  
  File? _selectedFile;
  String _fileName = 'No file selected';
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UploadLoopDialogModel());
    _model.titleController ??= TextEditingController();
    _model.titleFocusNode ??= FocusNode();
    _model.descriptionController ??= TextEditingController();
    _model.descriptionFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _uploadLoop() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    if (_model.titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Subir a Cloudinary
      final uploadResult = await CloudinaryService.uploadAudioFile(
        _selectedFile!,
        _model.titleController.text.trim(),
      );

      if (uploadResult['success'] == true) {
        setState(() {
          _uploadProgress = 0.5;
        });

        // Guardar en Firestore
        await MusicLoopRecord.collection.add(
          createMusicLoopRecordData(
            title: _model.titleController.text.trim(),
            description: _model.descriptionController.text.trim(),
            cloudinaryUrl: uploadResult['url'],
            cloudinaryPublicId: uploadResult['public_id'],
            duration: uploadResult['duration'],
            uploadedBy: currentUserUid,
            createdAt: getCurrentTimestamp,
            fileSize: uploadResult['bytes'],
            resourceType: uploadResult['resource_type'],
          ),
        );

        setState(() {
          _uploadProgress = 1.0;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loop uploaded successfully!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception(uploadResult['error'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upload Music Loop',
                    style: FlutterFlowTheme.of(context).headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // File picker button
              InkWell(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.audio_file,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fileName,
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.upload_file,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title input
              TextFormField(
                controller: _model.titleController,
                focusNode: _model.titleFocusNode,
                enabled: !_isUploading,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter loop title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: FlutterFlowTheme.of(context).primaryBackground,
                ),
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
              const SizedBox(height: 16),

              // Description input
              TextFormField(
                controller: _model.descriptionController,
                focusNode: _model.descriptionFocusNode,
                enabled: !_isUploading,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter loop description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: FlutterFlowTheme.of(context).primaryBackground,
                ),
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
              const SizedBox(height: 24),

              // Upload progress
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: FlutterFlowTheme.of(context).alternate,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toInt()}%',
                      style: FlutterFlowTheme.of(context).bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Upload button
              FFButtonWidget(
                onPressed: _isUploading ? null : _uploadLoop,
                text: _isUploading ? 'Uploading...' : 'Upload Loop',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 50,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                      ),
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
