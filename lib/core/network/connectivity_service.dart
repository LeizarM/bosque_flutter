import 'dart:async';
import 'dart:io';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estados posibles de la conexión
enum ConnectionStatus {
  /// Conectado y servidor alcanzable
  connected,

  /// Tiene red pero el servidor no responde (o responde lento)
  unstable,

  /// Sin conexión a internet
  disconnected,

  /// Verificando estado de conexión
  checking,
}

/// Estado completo de la conectividad
class ConnectivityState {
  final ConnectionStatus status;
  final String message;
  final DateTime lastChecked;

  const ConnectivityState({
    required this.status,
    required this.message,
    required this.lastChecked,
  });

  ConnectivityState copyWith({
    ConnectionStatus? status,
    String? message,
    DateTime? lastChecked,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheck;

  ConnectivityNotifier()
    : super(
        ConnectivityState(
          status: ConnectionStatus.checking,
          message: 'Verificando conexión...',
          lastChecked: DateTime.now(),
        ),
      ) {
    _init();
  }

  void _init() {
    // En web, connectivity_plus no es confiable → solo hacer check inicial y periódico
    if (!kIsWeb) {
      _subscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );
    }

    // Asumir conectado inicialmente para no bloquear el arranque de la app.
    // La verificación real se hace después de un delay para que la UI cargue primero.
    state = ConnectivityState(
      status: ConnectionStatus.connected,
      message: 'Conectado',
      lastChecked: DateTime.now(),
    );

    // Retrasar la verificación inicial para no competir con SecureStorage
    // y otras operaciones de arranque que podrían colgar en dispositivos lentos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _checkConnectivity();
    });

    // Verificación periódica cada 30 segundos
    _periodicCheck = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      state = ConnectivityState(
        status: ConnectionStatus.disconnected,
        message: 'Sin conexión a internet',
        lastChecked: DateTime.now(),
      );
    } else {
      // Tiene red, verificar si el servidor responde
      _checkServerReachability();
    }
  }

  Future<void> _checkConnectivity() async {
    // En web, connectivity_plus no es confiable → verificar directo con el servidor
    if (kIsWeb) {
      await _checkServerReachability();
      return;
    }

    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        state = ConnectivityState(
          status: ConnectionStatus.disconnected,
          message: 'Sin conexión a internet',
          lastChecked: DateTime.now(),
        );
      } else {
        await _checkServerReachability();
      }
    } catch (e) {
      console('Error verificando conectividad: $e');
      state = ConnectivityState(
        status: ConnectionStatus.unstable,
        message: 'No se pudo verificar la conexión',
        lastChecked: DateTime.now(),
      );
    }
  }

  Future<void> _checkServerReachability() async {
    if (kIsWeb) {
      // En web, dart:io no funciona y CORS puede bloquear peticiones de verificación.
      // Si llegamos aquí es porque el sistema reportó conexión de red → asumir conectado.
      state = ConnectivityState(
        status: ConnectionStatus.connected,
        message: 'Conectado',
        lastChecked: DateTime.now(),
      );
      return;
    }

    try {
      final uri = Uri.parse(AppConstants.baseUrl);
      final host = uri.host;
      final port = uri.port;

      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      stopwatch.stop();
      socket.destroy();

      final latency = stopwatch.elapsedMilliseconds;

      if (latency > 3000) {
        state = ConnectivityState(
          status: ConnectionStatus.unstable,
          message: 'Conexión lenta (${latency}ms)',
          lastChecked: DateTime.now(),
        );
      } else {
        state = ConnectivityState(
          status: ConnectionStatus.connected,
          message: 'Conectado (${latency}ms)',
          lastChecked: DateTime.now(),
        );
      }
    } on SocketException {
      state = ConnectivityState(
        status: ConnectionStatus.unstable,
        message: 'Servidor no alcanzable',
        lastChecked: DateTime.now(),
      );
    } on TimeoutException {
      state = ConnectivityState(
        status: ConnectionStatus.unstable,
        message: 'Servidor no responde (timeout)',
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      console('Error al verificar servidor: $e');
      state = ConnectivityState(
        status: ConnectionStatus.unstable,
        message: 'Error de conexión',
        lastChecked: DateTime.now(),
      );
    }
  }

  /// Forzar una verificación manual
  Future<void> retry() async {
    state = state.copyWith(
      status: ConnectionStatus.checking,
      message: 'Verificando conexión...',
    );
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _periodicCheck?.cancel();
    super.dispose();
  }
}

/// Provider global de conectividad
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
      (ref) => ConnectivityNotifier(),
    );
