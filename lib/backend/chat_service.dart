import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../flutter_flow/flutter_flow_util.dart';

import '../../backend/backend.dart';
import 'logger_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get real-time chat messages for a project
  Stream<List<ChatMessageRecord>> getProjectMessagesStream(
    String projectId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('messages')
        .where('project_id', isEqualTo: projectId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageRecord.fromSnapshot(doc))
          .toList();
    });
  }

  /// Send a message to project chat
  Future<ChatMessageRecord> sendMessage({
    required String projectId,
    required String message,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get user info from Firestore
      final userDoc = await _firestore.collection('user').doc(currentUser.uid).get();
      final userData = UserRecord.fromSnapshot(userDoc);

      final docRef = await _firestore.collection('messages').add(
        mapToFirestore(
          createChatMessageRecordData(
            projectId: projectId,
            senderUid: currentUser.uid,
            senderName: userData.displayName,
            senderPhotoUrl: userData.photoUrl,
            message: message,
            createdAt: getCurrentTimestamp,
            attachmentUrl: attachmentUrl,
            attachmentType: attachmentType,
            readBy: [currentUser.uid],
          ),
        ),
      );

      // Fetch the created message
      final doc = await docRef.get();
      return ChatMessageRecord.fromSnapshot(doc);
    } catch (e) {
      LoggerService.error('sending message', e);
      rethrow;
    }
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final messageRef = _firestore.collection('messages').doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) return;

      final currentReadBy = List<String>.from(messageDoc.get('read_by') ?? []);
      if (!currentReadBy.contains(currentUser.uid)) {
        currentReadBy.add(currentUser.uid);
        await messageRef.update({'read_by': currentReadBy});
      }
    } catch (e) {
      LoggerService.error('marking message as read', e);
    }
  }

  /// Edit a message
  Future<void> editMessage({
    required String messageId,
    required String newMessage,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _firestore.collection('messages').doc(messageId).update({
        'message': newMessage,
        'modified_at': FieldValue.serverTimestamp(),
        'is_edited': true,
      });
    } catch (e) {
      LoggerService.error('editing message', e);
      rethrow;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      LoggerService.error('deleting message', e);
      rethrow;
    }
  }

  /// Get unread message count for a project
  Stream<int> getUnreadCountStream(String projectId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('messages')
        .where('project_id', isEqualTo: projectId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final message = ChatMessageRecord.fromSnapshot(doc);
        final readBy = message.readBy;
        // Count messages not read by current user
        if (!readBy.contains(currentUser.uid)) {
          unreadCount++;
        }
      }
      return unreadCount;
    });
  }

  /// Get unread messages for a project (filtered client-side)
  Stream<List<ChatMessageRecord>> getUnreadMessagesStream(String projectId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('messages')
        .where('project_id', isEqualTo: projectId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageRecord.fromSnapshot(doc))
          .where((msg) {
            // Filter client-side: only messages not read by current user
            final readBy = msg.readBy;
            return !readBy.contains(currentUser.uid);
          })
          .toList();
    });
  }

  /// Search messages in a project
  Stream<List<ChatMessageRecord>> searchMessages({
    required String projectId,
    required String query,
  }) {
    return _firestore
        .collection('messages')
        .where('project_id', isEqualTo: projectId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageRecord.fromSnapshot(doc))
          .where((msg) =>
              msg.message.toLowerCase().contains(query.toLowerCase()) ||
              msg.senderName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// Watch real-time presence in a project
  Future<void> setUserPresence({
    required String projectId,
    required bool isOnline,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final presenceRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('presence')
          .doc(currentUser.uid);

      if (isOnline) {
        await presenceRef.set({
          'user_id': currentUser.uid,
          'online_at': FieldValue.serverTimestamp(),
          'last_heartbeat': FieldValue.serverTimestamp(),
        });
      } else {
        await presenceRef.delete();
      }
    } catch (e) {
      LoggerService.error('setting user presence', e);
    }
  }

  /// Get users currently online in a project
  Stream<List<String>> getOnlineUsersStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('presence')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.get('user_id') as String).toList();
    });
  }
}

// Global chat service instance
final chatService = ChatService();
