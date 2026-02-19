import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'logger_service.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();

  // Cloudinary credentials (should come from environment in production)
  static const String cloudName = 'dsfazlofc';
  static const String apiKey = '375549546746736';
  static const String apiSecret = '2pvXZo07QeUjClYKqHgFBoMjoVI';
  static const String uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
  static const String resourceUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/resources';

  late Dio _dio;
  final _firestore = FirebaseFirestore.instance;

  factory CloudinaryService() {
    return _instance;
  }

  CloudinaryService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
  }

  /// Upload audio file to Cloudinary
  Future<Map<String, dynamic>> uploadAudioFile({
    required PlatformFile file,
    required String projectId,
    String? userId,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
        'upload_preset': 'musical_studio',
        'resource_type': 'auto',
        'folder': 'musical_studio/projects/$projectId',
        'public_id': '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
        'tags': ['musical_studio', projectId, if (userId != null) userId],
        'metadata': jsonEncode({
          'projectId': projectId,
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        }),
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Save reference to Firestore
        await _saveAudioMetadata(
          projectId: projectId,
          userId: userId,
          cloudinaryData: data,
        );

        return {
          'success': true,
          'url': data['secure_url'],
          'publicId': data['public_id'],
          'cloudinaryId': data['public_id'],
          'duration': data['duration'],
          'size': data['bytes'],
          'format': data['format'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to upload file: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Upload error: $e',
      };
    }
  }

  /// Download audio file from Cloudinary
  Future<bool> downloadAudioFile({
    required String url,
    required String fileName,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.download(
        url,
        fileName,
        onReceiveProgress: onReceiveProgress,
      );

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.info('Download error: e');
      return false;
    }
  }

  /// Get list of audio files for a project
  Future<List<Map<String, dynamic>>> getProjectAudioFiles(
      String projectId) async {
    try {
      final response = await _dio.get(
        '$resourceUrl/search',
        queryParameters: {
          'expression': 'folder:"musical_studio/projects/$projectId"',
          'max_results': 100,
        },
        options: Options(
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final resources = (data['resources'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        return resources.map((resource) {
          return {
            'url': resource['secure_url'],
            'publicId': resource['public_id'],
            'duration': resource['duration'],
            'size': resource['bytes'],
            'format': resource['format'],
            'uploadedAt': resource['created_at'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('fetching audio files', e);
      return [];
    }
  }

  /// Delete audio file from Cloudinary
  Future<bool> deleteAudioFile(String publicId) async {
    try {
      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/resources/auto/delete',
        data: {'public_ids': publicId},
        queryParameters: {
          'api_key': apiKey,
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.info('Delete error: e');
      return false;
    }
  }

  /// Save audio metadata to Firestore
  Future<void> _saveAudioMetadata({
    required String projectId,
    required String? userId,
    required Map<String, dynamic> cloudinaryData,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('audio_files')
          .add({
        'cloudinaryId': cloudinaryData['public_id'],
        'url': cloudinaryData['secure_url'],
        'fileName': cloudinaryData['original_filename'],
        'duration': cloudinaryData['duration'],
        'size': cloudinaryData['bytes'],
        'format': cloudinaryData['format'],
        'userId': userId,
        'uploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      LoggerService.error('saving audio metadata', e);
    }
  }

  /// Get audio file URL with transformations (optional)
  String getTransformedUrl(
    String publicId, {
    int? width,
    int? height,
    String? quality,
  }) {
    String url = 'https://res.cloudinary.com/$cloudName/auto/upload/';

    final transformations = <String>[];

    if (quality != null) transformations.add('q_$quality');
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');

    if (transformations.isNotEmpty) {
      url += '${transformations.join(',')}/';
    }

    url += publicId;
    return url;
  }
}
