import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'logger_service.dart';

class RealtimeSyncService {
  static final RealtimeSyncService _instance = RealtimeSyncService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _projectUpdates = BehaviorSubject<Map<String, dynamic>>();
  final _collaborators = BehaviorSubject<List<Map<String, dynamic>>>();
  final _syncStatus = BehaviorSubject<bool>(initialValue: false);

  StreamSubscription? _projectListener;
  StreamSubscription? _collaboratorListener;

  factory RealtimeSyncService() {
    return _instance;
  }

  RealtimeSyncService._internal();

  Stream<Map<String, dynamic>> get projectUpdatesStream => _projectUpdates.stream;
  Stream<List<Map<String, dynamic>>> get collaboratorsStream =>
      _collaborators.stream;
  Stream<bool> get syncStatusStream => _syncStatus.stream;

  // ===================== PROJECT SYNC =====================

  Future<void> watchProject(String projectId) async {
    _projectListener?.cancel();

    _projectListener = _firestore
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          _projectUpdates.add(snapshot.data() ?? {});
        }
      },
      onError: (error) {
        LoggerService.error('Error watching project', error);
        _syncStatus.add(false);
      },
    );
  }

  Future<void> updateProjectMetadata({
    required String projectId,
    required String name,
    String? description,
    Map<String, dynamic>? mixerState,
  }) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'name': name,
        'description': description,
        'mixerState': mixerState,
        'lastModified': FieldValue.serverTimestamp(),
      });
      _syncStatus.add(true);
    } catch (e) {
      print('Error updating project metadata: $e');
      _syncStatus.add(false);
      rethrow;
    }
  }

  // ===================== TRACK SYNC =====================

  Future<void> addTrackToProject({
    required String projectId,
    required String trackId,
    required String trackName,
    required String trackUrl,
    required String userId,
    double? volume,
    double? pan,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tracks')
          .doc(trackId)
          .set({
        'id': trackId,
        'name': trackName,
        'url': trackUrl,
        'userId': userId,
        'volume': volume ?? 1.0,
        'pan': pan ?? 0.0,
        'addedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _syncStatus.add(true);
    } catch (e) {
      print('Error adding track to project: $e');
      _syncStatus.add(false);
      rethrow;
    }
  }

  Stream<QuerySnapshot> watchProjectTracks(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tracks')
        .orderBy('addedAt')
        .snapshots();
  }

  Future<void> updateTrack({
    required String projectId,
    required String trackId,
    double? volume,
    double? pan,
    String? name,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (volume != null) updates['volume'] = volume;
      if (pan != null) updates['pan'] = pan;
      if (name != null) updates['name'] = name;

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tracks')
          .doc(trackId)
          .update(updates);
    } catch (e) {
      print('Error updating track: $e');
      rethrow;
    }
  }

  Future<void> removeTrack(String projectId, String trackId) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tracks')
          .doc(trackId)
          .delete();
    } catch (e) {
      print('Error removing track: $e');
      rethrow;
    }
  }

  // ===================== COLLABORATORS =====================

  Future<void> addCollaborator({
    required String projectId,
    required String userId,
    required String userEmail,
    required String role, // 'editor' or 'viewer'
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('collaborators')
          .doc(userId)
          .set({
        'userId': userId,
        'email': userEmail,
        'role': role,
        'addedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print('Error adding collaborator: $e');
      rethrow;
    }
  }

  Future<void> updateCollaboratorRole({
    required String projectId,
    required String userId,
    required String newRole,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('collaborators')
          .doc(userId)
          .update({'role': newRole});
    } catch (e) {
      print('Error updating collaborator role: $e');
      rethrow;
    }
  }

  Future<void> removeCollaborator(String projectId, String userId) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('collaborators')
          .doc(userId)
          .delete();
    } catch (e) {
      print('Error removing collaborator: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> watchProjectCollaborators(String projectId) {
    _collaboratorListener?.cancel();

    _collaboratorListener = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('collaborators')
        .snapshots()
        .listen(
      (snapshot) {
        final collaborators = snapshot.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();
        _collaborators.add(collaborators);
      },
    );

    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('collaborators')
        .snapshots();
  }

  // ===================== CHAT MESSAGES =====================

  Future<void> sendChatMessage({
    required String projectId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('chat')
          .add({
        'userId': userId,
        'userName': userName,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending chat message: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> watchChatMessages(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // ===================== SYNC RESOLUTION =====================

  Future<Map<String, dynamic>?> getLatestProjectState(
      String projectId) async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      return doc.data();
    } catch (e) {
      print('Error getting project state: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getProjectTracks(
      String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tracks')
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting project tracks: $e');
      return [];
    }
  }

  // ===================== OFFLINE SYNC SUPPORT =====================

  Future<void> queueOfflineChange({
    required String projectId,
    required String changeType, // 'track_added', 'track_updated', etc.
    required Map<String, dynamic> changeData,
  }) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('offline_queue')
          .add({
        'type': changeType,
        'data': changeData,
        'timestamp': FieldValue.serverTimestamp(),
        'synced': false,
      });
    } catch (e) {
      print('Error queuing offline change: $e');
      rethrow;
    }
  }

  Future<void> processPendingChanges(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('offline_queue')
          .where('synced', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final changeType = data['type'] as String;
        final changeData = data['data'] as Map<String, dynamic>;

        // Process based on change type
        switch (changeType) {
          case 'track_added':
            // Handle track addition
            break;
          case 'track_updated':
            // Handle track update
            break;
          case 'track_removed':
            // Handle track removal
            break;
        }

        // Mark as synced
        await doc.reference.update({'synced': true});
      }

      _syncStatus.add(true);
    } catch (e) {
      LoggerService.error('Error processing pending changes', e);
      _syncStatus.add(false);
      rethrow;
    }
  }

  // ===================== CLEANUP =====================

  Future<void> dispose() async {
    try {
      // Cancelar listeners Firestore
      await _projectListener?.cancel();
      await _collaboratorListener?.cancel();
      
      // Cerrar BehaviorSubjects
      if (!_projectUpdates.isClosed) await _projectUpdates.close();
      if (!_collaborators.isClosed) await _collaborators.close();
      if (!_syncStatus.isClosed) await _syncStatus.close();
      
      LoggerService.success('RealtimeSyncService disposed successfully');
    } catch (e) {
      LoggerService.error('Error disposing RealtimeSyncService', e);
    }
  }
}
