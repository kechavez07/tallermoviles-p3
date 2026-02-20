import '/flutter_flow/flutter_flow_util.dart';
import '/backend/realtime_sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page_widget.dart' show ChatPageWidget;
import 'package:flutter/material.dart';

class ChatPageModel extends FlutterFlowModel<ChatPageWidget> {
  // State fields
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  // Firebase services
  late RealtimeSyncService realtimeSyncService;
  late FirebaseFirestore firebaseFirestore;

  // Chat state
  Stream<QuerySnapshot>? chatMessagesStream;
  List<Map<String, dynamic>> messages = [];
  String? projectId;
  String? userId;
  String? userName;

  @override
  void initState(BuildContext context) {
    realtimeSyncService = RealtimeSyncService();
    firebaseFirestore = FirebaseFirestore.instance;
  }

  /// Initialize chat for project
  Future<void> initializeChat({
    required String pProjectId,
    required String pUserId,
    required String pUserName,
  }) async {
    projectId = pProjectId;
    userId = pUserId;
    userName = pUserName;

    // Watch chat messages
    chatMessagesStream = firebaseFirestore
        .collection('projects')
        .doc(projectId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Send message
  Future<void> sendMessage(String messageText) async {
    if (messageText.isEmpty ||
        projectId == null ||
        userId == null ||
        userName == null) return;

    try {
      await firebaseFirestore
          .collection('projects')
          .doc(projectId)
          .collection('chat')
          .add({
        'userId': userId,
        'userName': userName,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'avatar': 'https://ui-avatars.com/api/?name=$userName',
      });

      textController?.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Get messages as list (for non-stream widgets)
  Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final snapshot = await firebaseFirestore
          .collection('projects')
          .doc(projectId)
          .collection('chat')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
