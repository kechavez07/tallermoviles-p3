import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_flow/flutter_flow_util.dart';

import '../../backend/backend.dart';
import 'logger_service.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all projects for current user (owner or collaborator)
  Stream<List<ProjectRecord>> getUserProjectsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('projects')
        .where(Filter.or(
          Filter('owner_uid', isEqualTo: currentUser.uid),
          Filter('collaborators', arrayContains: currentUser.uid),
        ))
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectRecord.fromSnapshot(doc))
          .toList();
    });
  }

  /// Get all public projects (for discovery)
  Stream<List<ProjectRecord>> getPublicProjectsStream({int limit = 20}) {
    return _firestore
        .collection('projects')
        .where('is_public', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectRecord.fromSnapshot(doc))
          .toList();
    });
  }

  /// Get real-time project data with tracks (optimized with subcollection)
  Stream<ProjectWithTracks> getProjectWithTracksStream(String projectId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.error('User not authenticated');

    return _firestore
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .switchMap((projectSnap) {
      if (!projectSnap.exists) return Stream.error('Project not found');

      final project = ProjectRecord.fromSnapshot(projectSnap);

      // Verify user has access to this project
      final isOwner = project.ownerUid == currentUser.uid;
      final isCollaborator = project.collaborators.contains(currentUser.uid);
      final isPublic = project.isPublic;

      if (!isOwner && !isCollaborator && !isPublic) {
        return Stream.error('Access denied to this project');
      }

      // Get real-time tracks from root collection (but filtered by project_id)
      // For true subcollection optimization, tracks should be at:
      // projects/{projectId}/tracks/{trackId}
      // This requires migration, so for now, use root collection with proper filter
      return _firestore
          .collection('tracks')
          .where('project_id', isEqualTo: projectId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((tracksSnap) {
        final tracks = tracksSnap.docs
            .map((doc) => TrackRecord.fromSnapshot(doc))
            .toList();
        return ProjectWithTracks(project: project, tracks: tracks);
      });
    });
  }

  /// Alternative optimized method using subcollection (recommended for new apps)
  /// This assumes tracks are stored as: projects/{projectId}/tracks/{trackId}
  Stream<ProjectWithTracks> getProjectWithTracksStreamSubcollection(
      String projectId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.error('User not authenticated');

    return _firestore
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .switchMap((projectSnap) {
      if (!projectSnap.exists) return Stream.error('Project not found');

      final project = ProjectRecord.fromSnapshot(projectSnap);

      // Verify access
      final isOwner = project.ownerUid == currentUser.uid;
      final isCollaborator = project.collaborators.contains(currentUser.uid);
      final isPublic = project.isPublic;

      if (!isOwner && !isCollaborator && !isPublic) {
        return Stream.error('Access denied to this project');
      }

      // ✅ Optimized: Read tracks as subcollection
      // Single listener instead of two separate ones
      return _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tracks')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((tracksSnap) {
        final tracks = tracksSnap.docs
            .map((doc) => TrackRecord.fromSnapshot(doc))
            .toList();
        return ProjectWithTracks(project: project, tracks: tracks);
      });
    });
  }

  /// Create a new project
  Future<ProjectRecord> createProject({
    required String name,
    required String description,
    bool isPublic = false,
    List<String>? tags,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final docRef = await _firestore.collection('projects').add(
        mapToFirestore(
          createProjectRecordData(
            name: name,
            description: description,
            ownerUid: currentUser.uid,
            collaborators: [],
            createdAt: getCurrentTimestamp,
            updatedAt: getCurrentTimestamp,
            isPublic: isPublic,
            trackCount: 0,
            tags: tags ?? [],
          ),
        ),
      );

      final doc = await docRef.get();
      return ProjectRecord.fromSnapshot(doc);
    } catch (e) {
      LoggerService.error('creating project', e);
      rethrow;
    }
  }

  /// Update project
  Future<void> updateProject({
    required String projectId,
    String? name,
    String? description,
    bool? isPublic,
    String? thumbnailUrl,
    List<String>? tags,
  }) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isPublic != null) 'is_public': isPublic,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (tags != null) 'tags': tags,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      LoggerService.error('updating project', e);
      rethrow;
    }
  }

  /// Add collaborator to project
  Future<void> addCollaborator({
    required String projectId,
    required String collaboratorUid,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final projectRef = _firestore.collection('projects').doc(projectId);
      final projectDoc = await projectRef.get();

      if (!projectDoc.exists) throw Exception('Project not found');

      final collaborators =
          List<String>.from(projectDoc.get('collaborators') ?? []);

      if (!collaborators.contains(collaboratorUid)) {
        collaborators.add(collaboratorUid);
        await projectRef.update({
          'collaborators': collaborators,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      LoggerService.error('adding collaborator', e);
      rethrow;
    }
  }

  /// Remove collaborator from project
  Future<void> removeCollaborator({
    required String projectId,
    required String collaboratorUid,
  }) async {
    try {
      final projectRef = _firestore.collection('projects').doc(projectId);
      final projectDoc = await projectRef.get();

      if (!projectDoc.exists) throw Exception('Project not found');

      final collaborators =
          List<String>.from(projectDoc.get('collaborators') ?? []);
      collaborators.remove(collaboratorUid);

      await projectRef.update({
        'collaborators': collaborators,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      LoggerService.error('removing collaborator', e);
      rethrow;
    }
  }

  /// Delete project (only owner)
  Future<void> deleteProject(String projectId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final projectDoc =
          await _firestore.collection('projects').doc(projectId).get();
      if (projectDoc.get('owner_uid') != currentUser.uid) {
        throw Exception('Only project owner can delete');
      }

      await _firestore.collection('projects').doc(projectId).delete();
    } catch (e) {
      LoggerService.error('deleting project', e);
      rethrow;
    }
  }

  /// Watch real-time project changes
  Stream<ProjectRecord> getProjectStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) throw Exception('Project not found');
      return ProjectRecord.fromSnapshot(snapshot);
    });
  }

  /// Get tracks for a project with real-time updates (optimized)
  Stream<List<TrackRecord>> getProjectTracksStream(String projectId) {
    return _firestore
        .collection('tracks')
        .where('project_id', isEqualTo: projectId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrackRecord.fromSnapshot(doc))
          .toList();
    });
  }
}

/// Model to combine project with its tracks
class ProjectWithTracks {
  final ProjectRecord project;
  final List<TrackRecord> tracks;

  ProjectWithTracks({
    required this.project,
    required this.tracks,
  });
}

// Global project service instance
final projectService = ProjectService();
