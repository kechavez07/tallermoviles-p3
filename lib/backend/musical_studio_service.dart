import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'cloudinary_service.dart';
import 'local_storage_service.dart';
import 'audio/audio_mixer_service.dart';
import 'realtime_sync_service.dart';
import 'environment_config.dart';
import 'logger_service.dart';

class MusicalStudioService {
  static final MusicalStudioService _instance =
      MusicalStudioService._internal();

  late final CloudinaryService _cloudinaryService;
  late final LocalStorageService _localStorageService;
  late final AudioMixerService _audioMixerService;
  late final RealtimeSyncService _realtimeSyncService;

  final _uuid = const Uuid();

  factory MusicalStudioService() {
    return _instance;
  }

  MusicalStudioService._internal();

  // ===================== INITIALIZATION =====================

  Future<void> initialize() async {
    await EnvironmentConfig.initialize();
    _cloudinaryService = CloudinaryService();
    _localStorageService = LocalStorageService();
    _audioMixerService = AudioMixerService();
    _realtimeSyncService = RealtimeSyncService();

    LoggerService.success('Musical Studio Service Initialized');
    LoggerService.info('Cloudinary Cloud: ${EnvironmentConfig.cloudinaryCloudName}');
  }

  // ===================== GETTERS FOR SUB-SERVICES =====================

  CloudinaryService get cloudinary => _cloudinaryService;
  LocalStorageService get localStorage => _localStorageService;
  AudioMixerService get audioMixer => _audioMixerService;
  RealtimeSyncService get realtimeSync => _realtimeSyncService;

  // ===================== PROJECT MANAGEMENT =====================

  Future<String> createProject({
    required String projectName,
    required String userId,
    String? description,
    String? thumbnail,
  }) async {
    try {
      final projectId = _uuid.v4();

      // Save to local storage
      await _localStorageService.createProject(
        id: projectId,
        name: projectName,
        userId: userId,
        description: description,
        thumbnail: thumbnail,
      );

      // Sync to Firebase
      await _realtimeSyncService.updateProjectMetadata(
        projectId: projectId,
        name: projectName,
        description: description,
      );

      // Queue for sync if offline
      await _localStorageService.addToSyncQueue(
        type: 'project',
        action: 'create',
        data: {
          'id': projectId,
          'name': projectName,
          'userId': userId,
          'description': description,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return projectId;
    } catch (e) {
      print('Error creating project: $e');
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _audioMixerService.stopAll();
      await _localStorageService.deleteProject(projectId);
      await _localStorageService.addToSyncQueue(
        type: 'project',
        action: 'delete',
        data: {'id': projectId},
      );
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }

  // ===================== AUDIO TRACK MANAGEMENT =====================

  Future<Map<String, dynamic>> uploadAudioToProject({
    required String projectId,
    required String userId,
    required PlatformFile audioFile,
    void Function(int, int)? onProgress,
  }) async {
    try {
      // Upload to Cloudinary
      final cloudinaryResult = await _cloudinaryService.uploadAudioFile(
        file: audioFile,
        projectId: projectId,
        userId: userId,
        onSendProgress: onProgress,
      );

      if (!cloudinaryResult['success']) {
        return cloudinaryResult;
      }

      // Create track ID
      final trackId = _uuid.v4();

      // Save metadata locally
      await _localStorageService.addAudioSample(
        sampleId: trackId,
        projectId: projectId,
        fileName: audioFile.name,
        filePath: audioFile.path ?? '',
        cloudinaryId: cloudinaryResult['cloudinaryId'],
        url: cloudinaryResult['url'],
        duration: cloudinaryResult['duration'],
        size: audioFile.size,
      );

      // Sync to Firebase
      await _realtimeSyncService.addTrackToProject(
        projectId: projectId,
        trackId: trackId,
        trackName: audioFile.name,
        trackUrl: cloudinaryResult['url'],
        userId: userId,
      );

      // Add to mixer
      await _audioMixerService.addTrack(
        trackId: trackId,
        trackName: audioFile.name,
        filePath: audioFile.path ?? '',
      );

      return {
        'success': true,
        'trackId': trackId,
        'url': cloudinaryResult['url'],
        'message': 'Track uploaded successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error uploading audio: $e',
      };
    }
  }

  Future<void> removeTrackFromProject({
    required String projectId,
    required String trackId,
  }) async {
    try {
      // Remove from mixer
      await _audioMixerService.removeTrack(trackId);

      // Remove from local storage
      await _localStorageService.deleteSample(trackId);

      // Remove from Firestore
      await _realtimeSyncService.removeTrack(projectId, trackId);

      // Queue for sync
      await _localStorageService.addToSyncQueue(
        type: 'sample',
        action: 'delete',
        data: {'trackId': trackId, 'projectId': projectId},
      );
    } catch (e) {
      print('Error removing track: $e');
      rethrow;
    }
  }

  // ===================== MIXER CONTROL =====================

  Future<void> setTrackVolume(String trackId, double volume) async {
    try {
      _audioMixerService.setTrackVolume(trackId, volume);

      // Save to local storage
      await _localStorageService.updateSampleVolume(trackId, volume);
    } catch (e) {
      print('Error setting track volume: $e');
    }
  }

  Future<void> setTrackPan(String trackId, double pan) async {
    try {
      _audioMixerService.setTrackPan(trackId, pan);

      // Save to local storage
      await _localStorageService.updateSamplePan(trackId, pan);
    } catch (e) {
      print('Error setting track pan: $e');
    }
  }

  Future<void> playMix() async {
    try {
      await _audioMixerService.playAll();
    } catch (e) {
      print('Error playing mix: $e');
      rethrow;
    }
  }

  Future<void> pauseMix() async {
    try {
      await _audioMixerService.pauseAll();
    } catch (e) {
      print('Error pausing mix: $e');
      rethrow;
    }
  }

  Future<void> stopMix() async {
    try {
      await _audioMixerService.stopAll();
    } catch (e) {
      print('Error stopping mix: $e');
      rethrow;
    }
  }

  // ===================== FAVORITES MANAGEMENT =====================

  Future<void> addToFavorites(String sampleId, String userId) async {
    try {
      await _localStorageService.addToFavorites(sampleId, userId);

      await _localStorageService.addToSyncQueue(
        type: 'favorite',
        action: 'create',
        data: {'sampleId': sampleId, 'userId': userId},
      );
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String sampleId, String userId) async {
    try {
      await _localStorageService.removeFromFavorites(sampleId, userId);

      await _localStorageService.addToSyncQueue(
        type: 'favorite',
        action: 'delete',
        data: {'sampleId': sampleId, 'userId': userId},
      );
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // ===================== SETTINGS MANAGEMENT =====================

  Future<void> saveSetting({
    required String userId,
    required String key,
    required String value,
  }) async {
    try {
      await _localStorageService.saveSetting(
        userId: userId,
        key: key,
        value: value,
      );
    } catch (e) {
      print('Error saving setting: $e');
      rethrow;
    }
  }

  Future<String?> getSetting(String userId, String key) async {
    try {
      return await _localStorageService.getSetting(userId, key);
    } catch (e) {
      print('Error getting setting: $e');
      return null;
    }
  }

  // ===================== COLLABORATION =====================

  Future<void> addCollaborator({
    required String projectId,
    required String userId,
    required String userEmail,
    required String role,
  }) async {
    try {
      await _realtimeSyncService.addCollaborator(
        projectId: projectId,
        userId: userId,
        userEmail: userEmail,
        role: role,
      );
    } catch (e) {
      print('Error adding collaborator: $e');
      rethrow;
    }
  }

  Future<void> sendChatMessage({
    required String projectId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    try {
      await _realtimeSyncService.sendChatMessage(
        projectId: projectId,
        userId: userId,
        userName: userName,
        message: message,
      );
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // ===================== OFFLINE SYNC =====================

  Future<void> syncPendingChanges() async {
    try {
      final pendingItems = await _localStorageService.getPendingSyncItems();

      for (final item in pendingItems) {
        final syncId = item['id'] as String;
        try {
          // Process based on sync type
          // This would handle queued operations
          await _localStorageService.markAsSynced(syncId);
        } catch (e) {
          print('Error syncing item $syncId: $e');
        }
      }

      // Clear synced items
      await _localStorageService.clearSyncedItems();
    } catch (e) {
      print('Error syncing pending changes: $e');
      rethrow;
    }
  }

  // ===================== CLEANUP =====================

  Future<void> dispose() async {
    await _audioMixerService.dispose();
    await _realtimeSyncService.dispose();
    await _localStorageService.closeDatabase();
  }
}
