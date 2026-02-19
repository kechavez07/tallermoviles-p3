import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChatMessageRecord extends FirestoreRecord {
  ChatMessageRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "project_id" field.
  String? _projectId;
  String get projectId => _projectId ?? '';
  bool hasProjectId() => _projectId != null;

  // "sender_uid" field.
  String? _senderUid;
  String get senderUid => _senderUid ?? '';
  bool hasSenderUid() => _senderUid != null;

  // "sender_name" field.
  String? _senderName;
  String get senderName => _senderName ?? '';
  bool hasSenderName() => _senderName != null;

  // "sender_photo_url" field.
  String? _senderPhotoUrl;
  String get senderPhotoUrl => _senderPhotoUrl ?? '';
  bool hasSenderPhotoUrl() => _senderPhotoUrl != null;

  // "message" field.
  String? _message;
  String get message => _message ?? '';
  bool hasMessage() => _message != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "modified_at" field.
  DateTime? _modifiedAt;
  DateTime? get modifiedAt => _modifiedAt;
  bool hasModifiedAt() => _modifiedAt != null;

  // "is_edited" field.
  bool? _isEdited;
  bool get isEdited => _isEdited ?? false;
  bool hasIsEdited() => _isEdited != null;

  // "read_by" field.
  List<String>? _readBy;
  List<String> get readBy => _readBy ?? const [];
  bool hasReadBy() => _readBy != null;

  // "attachment_url" field.
  String? _attachmentUrl;
  String get attachmentUrl => _attachmentUrl ?? '';
  bool hasAttachmentUrl() => _attachmentUrl != null;

  // "attachment_type" field.
  String? _attachmentType;
  String get attachmentType => _attachmentType ?? '';
  bool hasAttachmentType() => _attachmentType != null;

  void _initializeFields() {
    _projectId = snapshotData['project_id'] as String?;
    _senderUid = snapshotData['sender_uid'] as String?;
    _senderName = snapshotData['sender_name'] as String?;
    _senderPhotoUrl = snapshotData['sender_photo_url'] as String?;
    _message = snapshotData['message'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _modifiedAt = snapshotData['modified_at'] as DateTime?;
    _isEdited = snapshotData['is_edited'] as bool?;
    _readBy = getDataList(snapshotData['read_by']);
    _attachmentUrl = snapshotData['attachment_url'] as String?;
    _attachmentType = snapshotData['attachment_type'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('messages');

  static Stream<ChatMessageRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ChatMessageRecord.fromSnapshot(s));

  static Future<ChatMessageRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ChatMessageRecord.fromSnapshot(s));

  static ChatMessageRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ChatMessageRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ChatMessageRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ChatMessageRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ChatMessageRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ChatMessageRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createChatMessageRecordData({
  String? projectId,
  String? senderUid,
  String? senderName,
  String? senderPhotoUrl,
  String? message,
  DateTime? createdAt,
  DateTime? modifiedAt,
  bool? isEdited,
  List<String>? readBy,
  String? attachmentUrl,
  String? attachmentType,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'project_id': projectId,
      'sender_uid': senderUid,
      'sender_name': senderName,
      'sender_photo_url': senderPhotoUrl,
      'message': message,
      'created_at': createdAt,
      'modified_at': modifiedAt,
      'is_edited': isEdited,
      'read_by': readBy,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
    }.withoutNulls,
  );

  return firestoreData;
}

class ChatMessageRecordDocumentEquality implements Equality<ChatMessageRecord> {
  const ChatMessageRecordDocumentEquality();

  @override
  bool equals(ChatMessageRecord? e1, ChatMessageRecord? e2) {
    return e1?.projectId == e2?.projectId &&
        e1?.senderUid == e2?.senderUid &&
        e1?.senderName == e2?.senderName &&
        e1?.senderPhotoUrl == e2?.senderPhotoUrl &&
        e1?.message == e2?.message &&
        e1?.createdAt == e2?.createdAt &&
        e1?.modifiedAt == e2?.modifiedAt &&
        e1?.isEdited == e2?.isEdited &&
        listEquality.equals(e1?.readBy, e2?.readBy) &&
        e1?.attachmentUrl == e2?.attachmentUrl &&
        e1?.attachmentType == e2?.attachmentType;
  }

  @override
  int hash(ChatMessageRecord? e) => const ListEquality().hash([
        e?.projectId,
        e?.senderUid,
        e?.senderName,
        e?.senderPhotoUrl,
        e?.message,
        e?.createdAt,
        e?.modifiedAt,
        e?.isEdited,
        e?.readBy,
        e?.attachmentUrl,
        e?.attachmentType
      ]);

  @override
  bool isValidKey(Object? o) => o is ChatMessageRecord;
  
  ListEquality get listEquality => const ListEquality();
}
