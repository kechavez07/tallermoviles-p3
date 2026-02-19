import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProjectRecord extends FirestoreRecord {
  ProjectRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "owner_uid" field.
  String? _ownerUid;
  String get ownerUid => _ownerUid ?? '';
  bool hasOwnerUid() => _ownerUid != null;

  // "collaborators" field.
  List<String>? _collaborators;
  List<String> get collaborators => _collaborators ?? const [];
  bool hasCollaborators() => _collaborators != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updated_at" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "is_public" field.
  bool? _isPublic;
  bool get isPublic => _isPublic ?? false;
  bool hasIsPublic() => _isPublic != null;

  // "track_count" field.
  int? _trackCount;
  int get trackCount => _trackCount ?? 0;
  bool hasTrackCount() => _trackCount != null;

  // "thumbnail_url" field.
  String? _thumbnailUrl;
  String get thumbnailUrl => _thumbnailUrl ?? '';
  bool hasThumbnailUrl() => _thumbnailUrl != null;

  // "tags" field.
  List<String>? _tags;
  List<String> get tags => _tags ?? const [];
  bool hasTags() => _tags != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _description = snapshotData['description'] as String?;
    _ownerUid = snapshotData['owner_uid'] as String?;
    _collaborators = getDataList(snapshotData['collaborators']);
    _createdAt = snapshotData['created_at'] as DateTime?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
    _isPublic = snapshotData['is_public'] as bool?;
    _trackCount = castToType<int>(snapshotData['track_count']);
    _thumbnailUrl = snapshotData['thumbnail_url'] as String?;
    _tags = getDataList(snapshotData['tags']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('projects');

  static Stream<ProjectRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ProjectRecord.fromSnapshot(s));

  static Future<ProjectRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ProjectRecord.fromSnapshot(s));

  static ProjectRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ProjectRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ProjectRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ProjectRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ProjectRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ProjectRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createProjectRecordData({
  String? name,
  String? description,
  String? ownerUid,
  List<String>? collaborators,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool? isPublic,
  int? trackCount,
  String? thumbnailUrl,
  List<String>? tags,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'description': description,
      'owner_uid': ownerUid,
      'collaborators': collaborators,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_public': isPublic,
      'track_count': trackCount,
      'thumbnail_url': thumbnailUrl,
      'tags': tags,
    }.withoutNulls,
  );

  return firestoreData;
}

class ProjectRecordDocumentEquality implements Equality<ProjectRecord> {
  const ProjectRecordDocumentEquality();

  @override
  bool equals(ProjectRecord? e1, ProjectRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.description == e2?.description &&
        e1?.ownerUid == e2?.ownerUid &&
        listEquality.equals(e1?.collaborators, e2?.collaborators) &&
        e1?.createdAt == e2?.createdAt &&
        e1?.updatedAt == e2?.updatedAt &&
        e1?.isPublic == e2?.isPublic &&
        e1?.trackCount == e2?.trackCount &&
        e1?.thumbnailUrl == e2?.thumbnailUrl &&
        listEquality.equals(e1?.tags, e2?.tags);
  }

  @override
  int hash(ProjectRecord? e) => const ListEquality().hash([
        e?.name,
        e?.description,
        e?.ownerUid,
        e?.collaborators,
        e?.createdAt,
        e?.updatedAt,
        e?.isPublic,
        e?.trackCount,
        e?.thumbnailUrl,
        e?.tags
      ]);

  @override
  bool isValidKey(Object? o) => o is ProjectRecord;
}
