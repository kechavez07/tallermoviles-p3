import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FavoriteRecord extends FirestoreRecord {
  FavoriteRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_uid" field.
  String? _userUid;
  String get userUid => _userUid ?? '';
  bool hasUserUid() => _userUid != null;

  // "track_id" field.
  String? _trackId;
  String get trackId => _trackId ?? '';
  bool hasTrackId() => _trackId != null;

  // "project_id" field.
  String? _projectId;
  String get projectId => _projectId ?? '';
  bool hasProjectId() => _projectId != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "rating" field.
  int? _rating;
  int get rating => _rating ?? 0;
  bool hasRating() => _rating != null;

  // "notes" field.
  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  void _initializeFields() {
    _userUid = snapshotData['user_uid'] as String?;
    _trackId = snapshotData['track_id'] as String?;
    _projectId = snapshotData['project_id'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _rating = castToType<int>(snapshotData['rating']);
    _notes = snapshotData['notes'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('favorites');

  static Stream<FavoriteRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FavoriteRecord.fromSnapshot(s));

  static Future<FavoriteRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FavoriteRecord.fromSnapshot(s));

  static FavoriteRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FavoriteRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FavoriteRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FavoriteRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FavoriteRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FavoriteRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFavoriteRecordData({
  String? userUid,
  String? trackId,
  String? projectId,
  DateTime? createdAt,
  int? rating,
  String? notes,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_uid': userUid,
      'track_id': trackId,
      'project_id': projectId,
      'created_at': createdAt,
      'rating': rating,
      'notes': notes,
    }.withoutNulls,
  );

  return firestoreData;
}

class FavoriteRecordDocumentEquality implements Equality<FavoriteRecord> {
  const FavoriteRecordDocumentEquality();

  @override
  bool equals(FavoriteRecord? e1, FavoriteRecord? e2) {
    return e1?.userUid == e2?.userUid &&
        e1?.trackId == e2?.trackId &&
        e1?.projectId == e2?.projectId &&
        e1?.createdAt == e2?.createdAt &&
        e1?.rating == e2?.rating &&
        e1?.notes == e2?.notes;
  }

  @override
  int hash(FavoriteRecord? e) => const ListEquality().hash([
        e?.userUid,
        e?.trackId,
        e?.projectId,
        e?.createdAt,
        e?.rating,
        e?.notes
      ]);

  @override
  bool isValidKey(Object? o) => o is FavoriteRecord;
}
