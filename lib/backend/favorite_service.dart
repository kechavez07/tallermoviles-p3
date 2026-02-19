import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_flow/flutter_flow_util.dart';

import '../../backend/backend.dart';
import 'logger_service.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all favorites for current user (real-time)
  Stream<List<FavoriteRecord>> getUserFavoritesStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('favorites')
        .where('user_uid', isEqualTo: currentUser.uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FavoriteRecord.fromSnapshot(doc))
          .toList();
    });
  }

  /// Get favorites in a project (real-time)
  Stream<List<FavoriteRecord>> getProjectFavoritesStream(String projectId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('favorites')
        .where('project_id', isEqualTo: projectId)
        .where('user_uid', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FavoriteRecord.fromSnapshot(doc))
          .toList();
    });
  }

  /// Check if a track is favorited by current user
  Stream<bool> isTrackFavoritedStream(String trackId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);

    return _firestore
        .collection('favorites')
        .where('track_id', isEqualTo: trackId)
        .where('user_uid', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Add track to favorites
  Future<void> addToFavorites({
    required String trackId,
    required String projectId,
    int? rating,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if already favorited
      final existingDoc = await _firestore
          .collection('favorites')
          .where('track_id', isEqualTo: trackId)
          .where('user_uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (existingDoc.docs.isNotEmpty) {
        // Already favorited, just update
        await existingDoc.docs.first.reference.update({
          'rating': rating,
          'notes': notes,
        });
        return;
      }

      // Add new favorite
      await _firestore.collection('favorites').add(
        mapToFirestore(
          createFavoriteRecordData(
            userUid: currentUser.uid,
            trackId: trackId,
            projectId: projectId,
            createdAt: getCurrentTimestamp,
            rating: rating,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      LoggerService.error('adding to favorites', e);
      rethrow;
    }
  }

  /// Remove track from favorites
  Future<void> removeFromFavorites(String trackId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final querySnapshot = await _firestore
          .collection('favorites')
          .where('track_id', isEqualTo: trackId)
          .where('user_uid', isEqualTo: currentUser.uid)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      LoggerService.error('removing from favorites', e);
      rethrow;
    }
  }

  /// Rate a track
  Future<void> rateTrack({
    required String trackId,
    required int rating,
  }) async {
    try {
      if (rating < 0 || rating > 5) {
        throw Exception('Rating must be between 0 and 5');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection('favorites')
          .where('track_id', isEqualTo: trackId)
          .where('user_uid', isEqualTo: currentUser.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Track not in favorites');
      }

      await querySnapshot.docs.first.reference.update({
        'rating': rating,
      });
    } catch (e) {
      LoggerService.error('rating track', e);
      rethrow;
    }
  }

  /// Add notes to a favorite track
  Future<void> addNotesToFavorite({
    required String trackId,
    required String notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection('favorites')
          .where('track_id', isEqualTo: trackId)
          .where('user_uid', isEqualTo: currentUser.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Track not in favorites');
      }

      await querySnapshot.docs.first.reference.update({
        'notes': notes,
      });
    } catch (e) {
      LoggerService.error('adding notes', e);
      rethrow;
    }
  }

  /// Get top rated tracks in a project
  Stream<List<FavoriteRecord>> getTopRatedTracksStream({
    required String projectId,
    int limit = 10,
  }) {
    return _firestore
        .collection('favorites')
        .where('project_id', isEqualTo: projectId)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FavoriteRecord.fromSnapshot(doc))
          .toList();
    });
  }
}

// Global favorite service instance
final favoriteService = FavoriteService();
