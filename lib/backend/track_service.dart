import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_flow/flutter_flow_util.dart';

import '../../backend/backend.dart';

class TrackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all tracks in a project (real-time)
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

  /// Get tracks filtered by genre
  Stream<List<TrackRecord>> getTracksByGenreStream({
    required String projectId,
    required String genre,
  }) {
    return _firestore
        .collection('tracks')
        .where('project_id', isEqualTo: projectId)
        .where('genre', isEqualTo: genre)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrackRecord.fromSnapshot(doc))
          .toList();
    });
  }

  /// Create a new track
  Future<TrackRecord> createTrack({
    required String projectId,
    required String title,
    required String artist,
    String? genre,
    int? bpm,
    String? key,
    String? lyrics,
    String? audioUrl,
    String? coverUrl,
    int duration = 0,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final docRef = await _firestore.collection('tracks').add(
        mapToFirestore(
          createTrackRecordData(
            projectId: projectId,
            title: title,
            artist: artist,
            genre: genre,
            bpm: bpm,
            key: key,
            lyrics: lyrics,
            audioUrl: audioUrl,
            coverUrl: coverUrl,
            duration: duration,
            createdBy: currentUser.uid,
            createdAt: getCurrentTimestamp,
            updatedAt: getCurrentTimestamp,
            version: 1,
          ),
        ),
      );

      final doc = await docRef.get();
      return TrackRecord.fromSnapshot(doc);
    } catch (e) {
      print('Error creating track: $e');
      rethrow;
    }
  }

  /// Update track
  Future<void> updateTrack({
    required String trackId,
    String? title,
    String? artist,
    String? genre,
    int? bpm,
    String? key,
    String? lyrics,
    String? audioUrl,
    String? coverUrl,
    int? duration,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (artist != null) updateData['artist'] = artist;
      if (genre != null) updateData['genre'] = genre;
      if (bpm != null) updateData['bpm'] = bpm;
      if (key != null) updateData['key'] = key;
      if (lyrics != null) updateData['lyrics'] = lyrics;
      if (audioUrl != null) updateData['audio_url'] = audioUrl;
      if (coverUrl != null) updateData['cover_url'] = coverUrl;
      if (duration != null) updateData['duration'] = duration;

      updateData['updated_at'] = FieldValue.serverTimestamp();
      updateData['version'] = FieldValue.increment(1);

      await _firestore.collection('tracks').doc(trackId).update(updateData);
    } catch (e) {
      print('Error updating track: $e');
      rethrow;
    }
  }

  /// Delete track
  Future<void> deleteTrack(String trackId) async {
    try {
      await _firestore.collection('tracks').doc(trackId).delete();
    } catch (e) {
      print('Error deleting track: $e');
      rethrow;
    }
  }

  /// Get track stream for real-time updates
  Stream<TrackRecord> getTrackStream(String trackId) {
    return _firestore
        .collection('tracks')
        .doc(trackId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) throw Exception('Track not found');
      return TrackRecord.fromSnapshot(snapshot);
    });
  }

  /// Search tracks by title or artist
  Stream<List<TrackRecord>> searchTracks({
    required String projectId,
    required String query,
  }) {
    if (query.isEmpty) {
      return getProjectTracksStream(projectId);
    }

    return _firestore
        .collection('tracks')
        .where('project_id', isEqualTo: projectId)
        .orderBy('title')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrackRecord.fromSnapshot(doc))
          .toList();
    }).handleError((error) {
      print('Error searching tracks: $error');
      // Fallback to client-side search if index doesn't exist
      return getProjectTracksStream(projectId)
          .map((tracks) => tracks
              .where((track) =>
                  track.title.toLowerCase().contains(query.toLowerCase()) ||
                  track.artist.toLowerCase().contains(query.toLowerCase()))
              .toList());
    });
  }

  /// Get track history (versions) - optimized for single document
  Future<TrackRecord?> getTrackOnce(String trackId) async {
    try {
      final doc = await _firestore.collection('tracks').doc(trackId).get();
      if (!doc.exists) return null;
      return TrackRecord.fromSnapshot(doc);
    } catch (e) {
      print('Error getting track: $e');
      return null;
    }
  }
}

// Global track service instance
final trackService = TrackService();
