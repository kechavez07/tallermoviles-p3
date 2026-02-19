import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:estudio_musica_taller/offline/index.dart';

/// Configuración centralizada de Providers para el sistema offline
class OfflineProvidersSetup {
  /// Obtener lista de providers para MultiProvider
  static List<ChangeNotifierProvider> getProviders() => [
    // 1️⃣ ConnectivityManager - Monitorea cambios de red
    ChangeNotifierProvider(
      create: (_) => ConnectivityManager(),
      lazy: false, // Inicializar inmediatamente
    ),

    // 2️⃣ SyncService - Motor de sincronización
    ChangeNotifierProxyProvider<ConnectivityManager, SyncService>(
      create: (context) => 
        SyncService(context.read<ConnectivityManager>()),
      update: (context, connectivity, previous) =>
        previous ?? SyncService(connectivity),
      lazy: false,
    ),

    // 3️⃣ CacheManager - Caché inteligente
    ChangeNotifierProvider(
      create: (_) => CacheManager(),
      lazy: false,
    ),
  ];

  /// Configurar todos los servicios (alternativa sin Provider)
  static Future<void> setupServicesManually() async {
    // Inicializar DatabaseManager
    final db = DatabaseManager();
    await db.database; // Fuerza inicialización

    // Inicializar ConnectivityManager
    final connectivity = ConnectivityManager();
    
    // Registrar callback de conectividad
    connectivity.onConnectivityChanged((state) {
      debugPrint(
        '[OfflineSetup] Conectividad cambió a: ${state.name}',
      );
    });

    debugPrint('[OfflineSetup] Servicios offline inicializados');
  }

  /// Limpiar recursos
  static Future<void> cleanup() async {
    final db = DatabaseManager();
    await db.close();
    debugPrint('[OfflineSetup] Recursos liberados');
  }
}

/// Usar en main.dart de la siguiente forma:
/// 
/// ```dart
/// import 'package:estudio_musica_taller/offline/setup/offline_providers_setup.dart';
/// 
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Inicializar Firebase
///   await Firebase.initializeApp(
///     options: DefaultFirebaseOptions.currentPlatform,
///   );
///   
///   // Inicializar servicios offline
///   await OfflineProvidersSetup.setupServicesManually();
///   
///   runApp(
///     MultiProvider(
///       providers: OfflineProvidersSetup.getProviders(),
///       child: const MyApp(),
///     ),
///   );
/// }
/// 
/// // En cada pantalla:
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final connectivity = context.watch<ConnectivityManager>();
///     final syncService = context.watch<SyncService>();
///     final cache = context.watch<CacheManager>();
///     
///     return Scaffold(
///       appBar: AppBar(
///         title: Text('Modo: ${connectivity.isOnline ? "Online" : "Offline"}'),
///       ),
///     );
///   }
/// }
/// ```
