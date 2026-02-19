import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// Mixin para garantizar cleanup automático de streams y BehaviorSubjects
/// Uso: class MyService with StreamCleanupMixin { ... }
mixin StreamCleanupMixin {
  final List<Stream<dynamic>> _managedStreams = [];
  final List<Subject<dynamic>> _managedSubjects = [];

  /// Registrar un BehaviorSubject para limpieza automática
  void registerSubject<T>(Subject<T> subject) {
    _managedSubjects.add(subject);
  }

  /// Registrar un Stream para tracking (principalmente para Subjects)
  void registerStream<T>(Stream<T> stream) {
    _managedStreams.add(stream);
  }

  /// Cleanup completo - llamar en dispose()
  Future<void> cleanupStreams() async {
    // Cerrar todos los subjects
    for (final subject in _managedSubjects) {
      if (!subject.isClosed) {
        try {
          await subject.close();
        } catch (e) {
          print('Error cerrando subject: $e');
        }
      }
    }

    _managedStreams.clear();
    _managedSubjects.clear();
  }

  /// Verificar si hay subjects abiertos (para debugging)
  int get openSubjectsCount => _managedSubjects.length;
}

/// Extension para hacer más fácil usar BehaviorSubjects con cleanup
extension BehaviorSubjectCleanup<T> on BehaviorSubject<T> {
  /// Cerrar subject de forma segura
  Future<void> safeClose() async {
    if (!isClosed) {
      try {
        await close();
      } catch (e) {
        debugPrint('Error cerrando BehaviorSubject: $e');
      }
    }
  }
}

/// Extension para StreamSubscription cleanup múltiple
extension StreamSubscriptionList on List<StreamSubscription<dynamic>> {
  /// Cancelar todas las subscripciones
  Future<void> cancelAll() async {
    for (final sub in this) {
      try {
        // Dar tiempo al scheduler
        await Future.delayed(Duration.zero);
        await sub.cancel();
      } catch (e) {
        debugPrint('Error cancelando subscription: $e');
      }
    }
    clear();
  }
}
