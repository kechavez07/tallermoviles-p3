import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SettingsRecord extends FirestoreRecord {
  SettingsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_uid" field.
  String? _userUid;
  String get userUid => _userUid ?? '';
  bool hasUserUid() => _userUid != null;

  // "theme_mode" field.
  String? _themeMode;
  String get themeMode => _themeMode ?? 'light';
  bool hasThemeMode() => _themeMode != null;

  // "notifications_enabled" field.
  bool? _notificationsEnabled;
  bool get notificationsEnabled => _notificationsEnabled ?? true;
  bool hasNotificationsEnabled() => _notificationsEnabled != null;

  // "default_bpm" field.
  int? _defaultBpm;
  int get defaultBpm => _defaultBpm ?? 120;
  bool hasDefaultBpm() => _defaultBpm != null;

  // "default_key" field.
  String? _defaultKey;
  String get defaultKey => _defaultKey ?? 'C';
  bool hasDefaultKey() => _defaultKey != null;

  // "auto_save" field.
  bool? _autoSave;
  bool get autoSave => _autoSave ?? true;
  bool hasAutoSave() => _autoSave != null;

  // "auto_save_interval" field.
  int? _autoSaveInterval;
  int get autoSaveInterval => _autoSaveInterval ?? 5;
  bool hasAutoSaveInterval() => _autoSaveInterval != null;

  // "privacy_level" field.
  String? _privacyLevel;
  String get privacyLevel => _privacyLevel ?? 'private';
  bool hasPrivacyLevel() => _privacyLevel != null;

  // "preferred_format" field.
  String? _preferredFormat;
  String get preferredFormat => _preferredFormat ?? 'mp3';
  bool hasPreferredFormat() => _preferredFormat != null;

  // "updated_at" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "language" field.
  String? _language;
  String get language => _language ?? 'en';
  bool hasLanguage() => _language != null;

  void _initializeFields() {
    _userUid = snapshotData['user_uid'] as String?;
    _themeMode = snapshotData['theme_mode'] as String?;
    _notificationsEnabled = snapshotData['notifications_enabled'] as bool?;
    _defaultBpm = castToType<int>(snapshotData['default_bpm']);
    _defaultKey = snapshotData['default_key'] as String?;
    _autoSave = snapshotData['auto_save'] as bool?;
    _autoSaveInterval = castToType<int>(snapshotData['auto_save_interval']);
    _privacyLevel = snapshotData['privacy_level'] as String?;
    _preferredFormat = snapshotData['preferred_format'] as String?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
    _language = snapshotData['language'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('settings');

  static Stream<SettingsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SettingsRecord.fromSnapshot(s));

  static Future<SettingsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SettingsRecord.fromSnapshot(s));

  static SettingsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SettingsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SettingsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SettingsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SettingsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SettingsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSettingsRecordData({
  String? userUid,
  String? themeMode,
  bool? notificationsEnabled,
  int? defaultBpm,
  String? defaultKey,
  bool? autoSave,
  int? autoSaveInterval,
  String? privacyLevel,
  String? preferredFormat,
  DateTime? updatedAt,
  String? language,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_uid': userUid,
      'theme_mode': themeMode,
      'notifications_enabled': notificationsEnabled,
      'default_bpm': defaultBpm,
      'default_key': defaultKey,
      'auto_save': autoSave,
      'auto_save_interval': autoSaveInterval,
      'privacy_level': privacyLevel,
      'preferred_format': preferredFormat,
      'updated_at': updatedAt,
      'language': language,
    }.withoutNulls,
  );

  return firestoreData;
}

class SettingsRecordDocumentEquality implements Equality<SettingsRecord> {
  const SettingsRecordDocumentEquality();

  @override
  bool equals(SettingsRecord? e1, SettingsRecord? e2) {
    return e1?.userUid == e2?.userUid &&
        e1?.themeMode == e2?.themeMode &&
        e1?.notificationsEnabled == e2?.notificationsEnabled &&
        e1?.defaultBpm == e2?.defaultBpm &&
        e1?.defaultKey == e2?.defaultKey &&
        e1?.autoSave == e2?.autoSave &&
        e1?.autoSaveInterval == e2?.autoSaveInterval &&
        e1?.privacyLevel == e2?.privacyLevel &&
        e1?.preferredFormat == e2?.preferredFormat &&
        e1?.updatedAt == e2?.updatedAt &&
        e1?.language == e2?.language;
  }

  @override
  int hash(SettingsRecord? e) => const ListEquality().hash([
        e?.userUid,
        e?.themeMode,
        e?.notificationsEnabled,
        e?.defaultBpm,
        e?.defaultKey,
        e?.autoSave,
        e?.autoSaveInterval,
        e?.privacyLevel,
        e?.preferredFormat,
        e?.updatedAt,
        e?.language
      ]);

  @override
  bool isValidKey(Object? o) => o is SettingsRecord;
}
