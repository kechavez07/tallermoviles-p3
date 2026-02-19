import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TrackRecord extends FirestoreRecord {
  TrackRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "project_id" field.
  String? _projectId;
  String get projectId => _projectId ?? '';
  bool hasProjectId() => _projectId != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "artist" field.
  String? _artist;
  String get artist => _artist ?? '';
  bool hasArtist() => _artist != null;

  // "duration" field.
  int? _duration;
  int get duration => _duration ?? 0;
  bool hasDuration() => _duration != null;

  // "audio_url" field.
  String? _audioUrl;
  String get audioUrl => _audioUrl ?? '';
  bool hasAudioUrl() => _audioUrl != null;

  // "cover_url" field.
  String? _coverUrl;
  String get coverUrl => _coverUrl ?? '';
  bool hasCoverUrl() => _coverUrl != null;

  // "created_by" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updated_at" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "version" field.
  int? _version;
  int get version => _version ?? 1;
  bool hasVersion() => _version != null;

  // "bpm" field.
  int? _bpm;
  int get bpm => _bpm ?? 0;
  bool hasBpm() => _bpm != null;

  // "key" field.
  String? _key;
  String get key => _key ?? '';
  bool hasKey() => _key != null;

  // "genre" field.
  String? _genre;
  String get genre => _genre ?? '';
  bool hasGenre() => _genre != null;

  // "lyrics" field.
  String? _lyrics;
  String get lyrics => _lyrics ?? '';
  bool hasLyrics() => _lyrics != null;

  void _initializeFields() {
    _projectId = snapshotData['project_id'] as String?;
    _title = snapshotData['title'] as String?;
    _artist = snapshotData['artist'] as String?;
    _duration = castToType<int>(snapshotData['duration']);
    _audioUrl = snapshotData['audio_url'] as String?;
    _coverUrl = snapshotData['cover_url'] as String?;
    _createdBy = snapshotData['created_by'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
    _version = castToType<int>(snapshotData['version']);
    _bpm = castToType<int>(snapshotData['bpm']);
    _key = snapshotData['key'] as String?;
    _genre = snapshotData['genre'] as String?;
    _lyrics = snapshotData['lyrics'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('tracks');

  static Stream<TrackRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TrackRecord.fromSnapshot(s));

  static Future<TrackRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TrackRecord.fromSnapshot(s));

  static TrackRecord fromSnapshot(DocumentSnapshot snapshot) => TrackRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TrackRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TrackRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TrackRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TrackRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTrackRecordData({
  String? projectId,
  String? title,
  String? artist,
  int? duration,
  String? audioUrl,
  String? coverUrl,
  String? createdBy,
  DateTime? createdAt,
  DateTime? updatedAt,
  int? version,
  int? bpm,
  String? key,
  String? genre,
  String? lyrics,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'project_id': projectId,
      'title': title,
      'artist': artist,
      'duration': duration,
      'audio_url': audioUrl,
      'cover_url': coverUrl,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'version': version,
      'bpm': bpm,
      'key': key,
      'genre': genre,
      'lyrics': lyrics,
    }.withoutNulls,
  );

  return firestoreData;
}

class TrackRecordDocumentEquality implements Equality<TrackRecord> {
  const TrackRecordDocumentEquality();

  @override
  bool equals(TrackRecord? e1, TrackRecord? e2) {
    return e1?.projectId == e2?.projectId &&
        e1?.title == e2?.title &&
        e1?.artist == e2?.artist &&
        e1?.duration == e2?.duration &&
        e1?.audioUrl == e2?.audioUrl &&
        e1?.coverUrl == e2?.coverUrl &&
        e1?.createdBy == e2?.createdBy &&
        e1?.createdAt == e2?.createdAt &&
        e1?.updatedAt == e2?.updatedAt &&
        e1?.version == e2?.version &&
        e1?.bpm == e2?.bpm &&
        e1?.key == e2?.key &&
        e1?.genre == e2?.genre &&
        e1?.lyrics == e2?.lyrics;
  }

  @override
  int hash(TrackRecord? e) => const ListEquality().hash([
        e?.projectId,
        e?.title,
        e?.artist,
        e?.duration,
        e?.audioUrl,
        e?.coverUrl,
        e?.createdBy,
        e?.createdAt,
        e?.updatedAt,
        e?.version,
        e?.bpm,
        e?.key,
        e?.genre,
        e?.lyrics
      ]);

  @override
  bool isValidKey(Object? o) => o is TrackRecord;
}
