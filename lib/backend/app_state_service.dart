import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

/// Servicio de estado global de la aplicación
class AppStateService extends ChangeNotifier {
  static final AppStateService _instance = AppStateService._internal();

  factory AppStateService() {
    return _instance;
  }

  AppStateService._internal() {
    _initializeConnectivity();
  }

  // Connectivity state
  final _isOnlineSubject = BehaviorSubject<bool>.seeded(true);
  Stream<bool> get isOnlineStream => _isOnlineSubject.stream;
  bool get isOnline => _isOnlineSubject.value;

  // Current project ID
  String? _currentProjectId;
  String? get currentProjectId => _currentProjectId;

  // Current user
  String _currentUserId = 'user_demo';
  String get currentUserId => _currentUserId;

  // Sync queue status
  final _syncQueueSubject = BehaviorSubject<int>.seeded(0);
  Stream<int> get syncQueueStream => _syncQueueSubject.stream;
  int get syncQueueCount => _syncQueueSubject.value;

  /// Initialize connectivity monitoring
  void _initializeConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      _isOnlineSubject.add(isOnline);
      notifyListeners();

      if (isOnline) {
        print('[AppState] 🌐 Conexión restaurada');
      } else {
        print('[AppState] 📴 Modo offline');
      }
    });
  }

  /// Set current project
  void setCurrentProject(String projectId) {
    _currentProjectId = projectId;
    notifyListeners();
  }

  /// Set current user (from auth)
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  /// Update sync queue count
  void updateSyncQueueCount(int count) {
    _syncQueueSubject.add(count);
    notifyListeners();
  }

  /// Clear state
  void reset() {
    _currentProjectId = null;
    _isOnlineSubject.add(true);
    _syncQueueSubject.add(0);
    notifyListeners();
  }

  @override
  void dispose() {
    _isOnlineSubject.close();
    _syncQueueSubject.close();
    super.dispose();
  }
}
