import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MusicLoopRecord extends FirestoreRecord {
  MusicLoopRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "cloudinary_url" field.
  String? _cloudinaryUrl;
  String get cloudinaryUrl => _cloudinaryUrl ?? '';
  bool hasCloudinaryUrl() => _cloudinaryUrl != null;

  // "cloudinary_public_id" field.
  String? _cloudinaryPublicId;
  String get cloudinaryPublicId => _cloudinaryPublicId ?? '';
  bool hasCloudinaryPublicId() => _cloudinaryPublicId != null;

  // "duration" field.
  double? _duration;
  double get duration => _duration ?? 0.0;
  bool hasDuration() => _duration != null;

  // "uploaded_by" field.
  String? _uploadedBy;
  String get uploadedBy => _uploadedBy ?? '';
  bool hasUploadedBy() => _uploadedBy != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "file_size" field.
  int? _fileSize;
  int get fileSize => _fileSize ?? 0;
  bool hasFileSize() => _fileSize != null;

  // "resource_type" field.
  String? _resourceType;
  String get resourceType => _resourceType ?? '';
  bool hasResourceType() => _resourceType != null;

  void _initializeFields() {
    _title = snapshotData['title'] as String?;
    _description = snapshotData['description'] as String?;
    _cloudinaryUrl = snapshotData['cloudinary_url'] as String?;
    _cloudinaryPublicId = snapshotData['cloudinary_public_id'] as String?;
    _duration = castToType<double>(snapshotData['duration']);
    _uploadedBy = snapshotData['uploaded_by'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _fileSize = castToType<int>(snapshotData['file_size']);
    _resourceType = snapshotData['resource_type'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('music_loops');

  static Stream<MusicLoopRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MusicLoopRecord.fromSnapshot(s));

  static Future<MusicLoopRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MusicLoopRecord.fromSnapshot(s));

  static MusicLoopRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MusicLoopRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MusicLoopRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MusicLoopRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MusicLoopRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MusicLoopRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMusicLoopRecordData({
  String? title,
  String? description,
  String? cloudinaryUrl,
  String? cloudinaryPublicId,
  double? duration,
  String? uploadedBy,
  DateTime? createdAt,
  int? fileSize,
  String? resourceType,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'title': title,
      'description': description,
      'cloudinary_url': cloudinaryUrl,
      'cloudinary_public_id': cloudinaryPublicId,
      'duration': duration,
      'uploaded_by': uploadedBy,
      'created_at': createdAt,
      'file_size': fileSize,
      'resource_type': resourceType,
    }.withoutNulls,
  );

  return firestoreData;
}

class MusicLoopRecordDocumentEquality implements Equality<MusicLoopRecord> {
  const MusicLoopRecordDocumentEquality();

  @override
  bool equals(MusicLoopRecord? e1, MusicLoopRecord? e2) {
    return e1?.title == e2?.title &&
        e1?.description == e2?.description &&
        e1?.cloudinaryUrl == e2?.cloudinaryUrl &&
        e1?.cloudinaryPublicId == e2?.cloudinaryPublicId &&
        e1?.duration == e2?.duration &&
        e1?.uploadedBy == e2?.uploadedBy &&
        e1?.createdAt == e2?.createdAt &&
        e1?.fileSize == e2?.fileSize &&
        e1?.resourceType == e2?.resourceType;
  }

  @override
  int hash(MusicLoopRecord? e) => const ListEquality().hash([
        e?.title,
        e?.description,
        e?.cloudinaryUrl,
        e?.cloudinaryPublicId,
        e?.duration,
        e?.uploadedBy,
        e?.createdAt,
        e?.fileSize,
        e?.resourceType
      ]);

  @override
  bool isValidKey(Object? o) => o is MusicLoopRecord;
}
