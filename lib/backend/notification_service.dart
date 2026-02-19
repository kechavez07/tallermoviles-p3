import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_flow/flutter_flow_util.dart';

import '../../backend/backend.dart';
import 'logger_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all notifications for current user (real-time)
  Stream<List<NotificationRecord>> getUserNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('recipient_uid', isEqualTo: currentUser.uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationRecord.fromSnapshot(doc))
          .toList();
    });
  }

  /// Get unread notifications count
  Stream<int> getUnreadCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('recipient_uid', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true, 'read_at': FieldValue.serverTimestamp()});
    } catch (e) {
      LoggerService.error('marking notification as read', e);
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('recipient_uid', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        await doc.reference
            .update({'read': true, 'read_at': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      LoggerService.error('marking all notifications as read', e);
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      LoggerService.error('deleting notification', e);
      rethrow;
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final notifications = await _firestore
          .collection('notifications')
          .where('recipient_uid', isEqualTo: currentUser.uid)
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      LoggerService.error('deleting all notifications', e);
      rethrow;
    }
  }

  /// Get notifications for a specific project
  Stream<List<NotificationRecord>> getProjectNotificationsStream(
      String projectId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('recipient_uid', isEqualTo: currentUser.uid)
        .where('data.projectId', isEqualTo: projectId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationRecord.fromSnapshot(doc))
          .toList();
    });
  }
}

/// Notification model for Firestore
class NotificationRecord {
  final String id;
  final String recipientUid;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool read;
  final DateTime? readAt;

  NotificationRecord({
    required this.id,
    required this.recipientUid,
    required this.title,
    required this.message,
    required this.data,
    required this.createdAt,
    required this.read,
    this.readAt,
  });

  factory NotificationRecord.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return NotificationRecord(
      id: snapshot.id,
      recipientUid: data['recipient_uid'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      data: data['data'] ?? {},
      createdAt: (data['created_at'] as Timestamp).toDate(),
      read: data['read'] ?? false,
      readAt: data['read_at'] != null
          ? (data['read_at'] as Timestamp).toDate()
          : null,
    );
  }
}

// Global notification service instance
final notificationService = NotificationService();
