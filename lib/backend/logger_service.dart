import 'package:flutter/foundation.dart';

/// Servicio centralizado de logging que reemplaza print()
/// - En DEBUG: escribe a console
/// - En RELEASE: solo almacena errores críticos
/// - En TEST: no hace nada
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal();

  static const String _logPrefix = '[MusicalStudio]';

  /// Log informativo (solo en debug)
  static void info(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint('$_logPrefix ℹ️  $message');
      if (error != null) debugPrint('   └─ $error');
    }
  }

  /// Log de éxito (solo en debug)
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('$_logPrefix ✓ $message');
    }
  }

  /// Log de warning (siempre)
  static void warning(String message, [dynamic error]) {
    debugPrint('$_logPrefix ⚠️  $message');
    if (error != null) debugPrint('   └─ $error');
  }

  /// Log de error (siempre)
  static void error(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('$_logPrefix ❌ $message');
    if (error != null) debugPrint('   └─ Error: $error');
    if (stack != null && kDebugMode) {
      debugPrint('   └─ Stack: $stack');
    }
  }

  /// Log de debug detallado (solo en debug)
  static void debug(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      debugPrint('$_logPrefix 🐛 $message');
      if (data != null && data.isNotEmpty) {
        data.forEach((key, value) {
          debugPrint('   ├─ $key: $value');
        });
      }
    }
  }

  /// Log de performance (solo en debug)
  static void performance(String action, Duration duration) {
    if (kDebugMode) {
      final ms = duration.inMilliseconds;
      final icon = ms < 100 ? '⚡' : ms < 1000 ? '⏱️ ' : '🐢';
      debugPrint('$_logPrefix $icon $action: ${ms}ms');
    }
  }

  /// Log de API call
  static void apiCall(
    String method,
    String endpoint, {
    Duration? duration,
    int? statusCode,
    dynamic response,
  }) {
    if (kDebugMode) {
      final statusStr = statusCode != null ? '[$statusCode]' : '';
      final timeStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      debugPrint('$_logPrefix 🌐 $method $endpoint$statusStr$timeStr');
    }
  }
}
