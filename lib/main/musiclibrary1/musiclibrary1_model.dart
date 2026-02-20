import '/components/musiclibrary/musiclibrary_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/musical_studio_service.dart';
import '/backend/local_storage_service.dart';
import 'musiclibrary1_widget.dart' show Musiclibrary1Widget;
import 'package:flutter/material.dart';

class Musiclibrary1Model extends FlutterFlowModel<Musiclibrary1Widget> {
  // Services
  late MusicalStudioService studioService;
  late LocalStorageService localStorageService;

  // Model for Musiclibrary component
  late MusiclibraryModel musiclibraryModel;

  // Projects state
  List<Map<String, dynamic>> projects = [];
  String? currentUserId;

  @override
  void initState(BuildContext context) {
    musiclibraryModel = createModel(context, () => MusiclibraryModel());
    studioService = MusicalStudioService();
    localStorageService = LocalStorageService();
  }

  /// Initialize services
  Future<void> initializeServices() async {
    try {
      await studioService.initialize();
      currentUserId = 'user_demo'; // In real app, get from auth
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  /// Create new project
  Future<String?> createProject({
    required String name,
    String? description,
  }) async {
    try {
      final projectId = await studioService.createProject(
        projectName: name,
        userId: currentUserId ?? 'user_demo',
        description: description,
      );
      return projectId;
    } catch (e) {
      print('Error creating project: $e');
      return null;
    }
  }

  /// Get all projects
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      // Fetch from local storage
      final projectsList =
          await localStorageService.getUserProjects(currentUserId ?? 'user_demo');
      projects = projectsList;
      return projectsList;
    } catch (e) {
      print('Error getting projects: $e');
      return [];
    }
  }

  /// Delete project
  Future<bool> deleteProject(String projectId) async {
    try {
      await studioService.deleteProject(projectId);
      projects.removeWhere((p) => p['id'] == projectId);
      return true;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }

  @override
  void dispose() {
    musiclibraryModel.dispose();
  }
}
