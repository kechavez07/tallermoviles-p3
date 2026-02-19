import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_flow/flutter_flow_util.dart';

import '../../backend/backend.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user settings (real-time)
  Stream<SettingsRecord?> getUserSettingsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(null);

    return _firestore
        .collection('settings')
        .where('user_uid', isEqualTo: currentUser.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return SettingsRecord.fromSnapshot(snapshot.docs.first);
    });
  }

  /// Get or create user settings
  Future<SettingsRecord> getUserSettingsOrCreate() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection('settings')
          .where('user_uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SettingsRecord.fromSnapshot(querySnapshot.docs.first);
      }

      // Create default settings
      final docRef = await _firestore.collection('settings').add(
        mapToFirestore(
          createSettingsRecordData(
            userUid: currentUser.uid,
            themeMode: 'light',
            notificationsEnabled: true,
            defaultBpm: 120,
            defaultKey: 'C',
            autoSave: true,
            autoSaveInterval: 5,
            privacyLevel: 'private',
            preferredFormat: 'mp3',
            updatedAt: getCurrentTimestamp,
            language: 'en',
          ),
        ),
      );

      final doc = await docRef.get();
      return SettingsRecord.fromSnapshot(doc);
    } catch (e) {
      print('Error getting or creating settings: $e');
      rethrow;
    }
  }

  /// Update user settings
  Future<void> updateSettings({
    String? themeMode,
    bool? notificationsEnabled,
    int? defaultBpm,
    String? defaultKey,
    bool? autoSave,
    int? autoSaveInterval,
    String? privacyLevel,
    String? preferredFormat,
    String? language,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection('settings')
          .where('user_uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Create settings if they don't exist
        await getUserSettingsOrCreate();
        return;
      }

      final updateData = <String, dynamic>{};
      if (themeMode != null) updateData['theme_mode'] = themeMode;
      if (notificationsEnabled != null) {
        updateData['notifications_enabled'] = notificationsEnabled;
      }
      if (defaultBpm != null) updateData['default_bpm'] = defaultBpm;
      if (defaultKey != null) updateData['default_key'] = defaultKey;
      if (autoSave != null) updateData['auto_save'] = autoSave;
      if (autoSaveInterval != null) {
        updateData['auto_save_interval'] = autoSaveInterval;
      }
      if (privacyLevel != null) updateData['privacy_level'] = privacyLevel;
      if (preferredFormat != null) {
        updateData['preferred_format'] = preferredFormat;
      }
      if (language != null) updateData['language'] = language;

      updateData['updated_at'] = FieldValue.serverTimestamp();

      await querySnapshot.docs.first.reference.update(updateData);
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(String themeMode) async {
    await updateSettings(themeMode: themeMode);
  }

  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await updateSettings(notificationsEnabled: enabled);
  }

  /// Set default BPM
  Future<void> setDefaultBpm(int bpm) async {
    if (bpm <= 0) throw Exception('BPM must be greater than 0');
    await updateSettings(defaultBpm: bpm);
  }

  /// Set default musical key
  Future<void> setDefaultKey(String key) async {
    final validKeys = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    if (!validKeys.contains(key)) {
      throw Exception('Invalid musical key');
    }
    await updateSettings(defaultKey: key);
  }

  /// Toggle auto-save
  Future<void> setAutoSave(bool enabled) async {
    await updateSettings(autoSave: enabled);
  }

  /// Set auto-save interval (in seconds)
  Future<void> setAutoSaveInterval(int seconds) async {
    if (seconds <= 0) throw Exception('Interval must be greater than 0');
    await updateSettings(autoSaveInterval: seconds);
  }

  /// Set privacy level
  Future<void> setPrivacyLevel(String privacyLevel) async {
    final validLevels = ['private', 'friends', 'public'];
    if (!validLevels.contains(privacyLevel)) {
      throw Exception('Invalid privacy level');
    }
    await updateSettings(privacyLevel: privacyLevel);
  }

  /// Set preferred audio format
  Future<void> setPreferredFormat(String format) async {
    final validFormats = ['mp3', 'wav', 'flac', 'aac', 'm4a'];
    if (!validFormats.contains(format.toLowerCase())) {
      throw Exception('Invalid audio format');
    }
    await updateSettings(preferredFormat: format.toLowerCase());
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    await updateSettings(language: language);
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final querySnapshot = await _firestore
          .collection('settings')
          .where('user_uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      await updateSettings(
        themeMode: 'light',
        notificationsEnabled: true,
        defaultBpm: 120,
        defaultKey: 'C',
        autoSave: true,
        autoSaveInterval: 5,
        privacyLevel: 'private',
        preferredFormat: 'mp3',
        language: 'en',
      );

      print('Settings reset to defaults');
    } catch (e) {
      print('Error resetting settings: $e');
      rethrow;
    }
  }
}

// Global settings service instance
final settingsService = SettingsService();
