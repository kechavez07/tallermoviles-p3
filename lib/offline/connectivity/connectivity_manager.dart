import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Estados de conectividad
enum NetworkState {
  online,
  offline,
  unknown,
}

/// Gestor de conectividad que monitorea cambios de red
class ConnectivityManager extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  
  NetworkState _networkState = NetworkState.unknown;
  late Stream<List<ConnectivityResult>> _connectivityStream;

  // Callbacks para cambios de conectividad
  Function(NetworkState)? _onConnectivityChanged;

  ConnectivityManager() {
    _connectivityStream = _connectivity.onConnectivityChanged;
    _initialize();
  }

  NetworkState get networkState => _networkState;

  bool get isOnline => _networkState == NetworkState.online;
  bool get isOffline => _networkState == NetworkState.offline;

  /// Inicializar monitoreo de conectividad
  Future<void> _initialize() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateNetworkState(result);
      
      // Escuchar cambios de conectividad
      _connectivityStream.listen((result) {
        _updateNetworkState(result);
      });
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
      _networkState = NetworkState.unknown;
    }
  }

  /// Actualizar estado de la red
  void _updateNetworkState(List<ConnectivityResult> result) {
    NetworkState newState;

    if (result.contains(ConnectivityResult.none)) {
      newState = NetworkState.offline;
    } else if (result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet)) {
      newState = NetworkState.online;
    } else {
      newState = NetworkState.unknown;
    }

    if (_networkState != newState) {
      _networkState = newState;
      notifyListeners();
      
      // Llamar callback si existe
      _onConnectivityChanged?.call(newState);
      
      // Log del cambio
      debugPrint(
        '''[Connectivity] Estado actualizado: ${newState.name}''',
      );
    }
  }

  /// Registrar callback para cambios de conectividad
  void onConnectivityChanged(Function(NetworkState) callback) {
    _onConnectivityChanged = callback;
  }

  /// Verificar conectividad manualmente
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateNetworkState(result);
      return isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
