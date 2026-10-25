/// Tiempo real para cualquier módulo: un canal STOMP sobre WebSocket nativo
/// (`/ws`, con el JWT en el frame CONNECT y reconexión con espera creciente) y
/// un estado versionado que, sin conexión, se mantiene al día por POST.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CANAL
// ═══════════════════════════════════════════════════════════════════════════

/// `ws://` o `wss://` sobre la misma base que la API, más [ruta] (`/ws`).
String urlTiempoReal(String base, {String ruta = AppConstants.wsTiempoReal}) {
  final uri = Uri.parse(base);
  final previa =
      uri.path.endsWith('/')
          ? uri.path.substring(0, uri.path.length - 1)
          : uri.path;
  return uri
      .replace(
        scheme: uri.scheme == 'https' ? 'wss' : 'ws',
        path: '$previa$ruta',
      )
      .toString();
}

/// Espera antes del intento [n] (desde 0): 1, 2, 4, 8, 16 y luego 30 s.
Duration esperaReintento(int n) =>
    Duration(seconds: math.min(30, 1 << math.min(n, 5)));

/// Lo que devuelve quien abre un canal: [cerrar] libera la conexión.
abstract interface class SuscripcionTiempoReal {
  void cerrar();
}

/// Una conexión STOMP con una suscripción a [destino]. Avisa cada cambio de
/// conexión una sola vez y reconecta sola; los mensajes llegan como JSON.
class CanalStomp implements SuscripcionTiempoReal {
  CanalStomp({
    required this.destino,
    required this.alMensaje,
    required this.alCambiarConexion,
    String? url,
    Future<String?> Function()? leerToken,
  }) : _url = url,
       _leerToken = leerToken ?? (() => SecureStorage().getToken());

  final String destino;
  final void Function(Map<String, dynamic> json) alMensaje;
  final void Function(bool conectado) alCambiarConexion;
  final String? _url;
  final Future<String?> Function() _leerToken;

  StompClient? _cliente;
  Timer? _reintento;
  int _intentos = 0;
  bool _cerrado = false;
  bool? _ultimoAviso;

  /// Abre la conexión; se llama una vez y el canal se ocupa de reconectar.
  Future<void> abrir() async {
    if (_cerrado) return;
    String? token;
    try {
      token = await _leerToken();
    } catch (_) {
      token = null;
    }
    if (_cerrado) return;

    late final StompClient cliente;
    cliente = StompClient(
      config: StompConfig(
        url: _url ?? urlTiempoReal(AppConstants.baseUrl),
        // La reconexión es propia: la del paquete es de espera fija.
        reconnectDelay: Duration.zero,
        connectionTimeout: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        stompConnectHeaders: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        onConnect: (_) {
          if (_cerrado || !identical(cliente, _cliente)) return;
          _intentos = 0;
          _avisar(true);
          cliente.subscribe(destination: destino, callback: _recibir);
        },
        onStompError: (_) => _caidaDe(cliente),
        onWebSocketError: (_) => _caidaDe(cliente),
        onWebSocketDone: () => _caidaDe(cliente),
        onDisconnect: (_) => _caidaDe(cliente),
      ),
    );
    _cliente = cliente;
    cliente.activate();
  }

  void _recibir(StompFrame frame) {
    final cuerpo = frame.body;
    if (_cerrado || cuerpo == null || cuerpo.isEmpty) return;
    try {
      final dato = jsonDecode(cuerpo);
      if (dato is! Map) return;
      // Tolera que el servidor lo envíe dentro del sobre { message, data }.
      final sobre = Map<String, dynamic>.from(dato);
      final interno = sobre['data'];
      alMensaje(
        !sobre.containsKey('version') && interno is Map
            ? Map<String, dynamic>.from(interno)
            : sobre,
      );
    } catch (_) {
      // Un mensaje mal formado no corta el canal: el siguiente lo corrige.
    }
  }

  /// Solo cuenta la caída del cliente vigente; uno viejo ya fue reemplazado.
  void _caidaDe(StompClient cliente) {
    if (identical(cliente, _cliente)) _caida();
  }

  void _caida() {
    if (_cerrado) return;
    _avisar(false);
    if (_reintento?.isActive ?? false) return;
    // El reintento se programa antes de soltar el cliente: si `deactivate`
    // vuelve a avisar la caída, encuentra el temporizador y no crea otro.
    _reintento = Timer(esperaReintento(_intentos++), abrir);
    final viejo = _cliente;
    _cliente = null;
    viejo?.deactivate();
  }

  void _avisar(bool conectado) {
    if (_ultimoAviso == conectado) return;
    _ultimoAviso = conectado;
    alCambiarConexion(conectado);
  }

  @override
  void cerrar() {
    _cerrado = true;
    _reintento?.cancel();
    _reintento = null;
    _cliente?.deactivate();
    _cliente = null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO VERSIONADO
// ═══════════════════════════════════════════════════════════════════════════

/// Lo que una pantalla en vivo dibuja: el último estado, si el canal está
/// conectado y el error de la carga inicial si no llegó nada.
@immutable
class EstadoTiempoReal<T> {
  final T? dato;
  final bool cargando;
  final bool conectado;
  final Object? error;

  const EstadoTiempoReal({
    this.dato,
    this.cargando = true,
    this.conectado = false,
    this.error,
  });

  EstadoTiempoReal<T> copyWith({
    T? dato,
    bool? cargando,
    bool? conectado,
    Object? error,
    bool limpiarError = false,
  }) => EstadoTiempoReal<T>(
    dato: dato ?? this.dato,
    cargando: cargando ?? this.cargando,
    conectado: conectado ?? this.conectado,
    error: limpiarError ? null : (error ?? this.error),
  );
}

/// Pide el estado por POST, se suscribe y solo reemplaza el estado si llega
/// una [version] mayor. Sin conexión, consulta por POST cada [intervaloSondeo].
class TiempoRealNotifier<T> extends StateNotifier<EstadoTiempoReal<T>> {
  TiempoRealNotifier({
    required Future<T?> Function() consultar,
    required VoidCallback Function(
      void Function(T) alRecibir,
      void Function(bool) alCambiarConexion,
    )
    suscribir,
    required int Function(T) version,
    this.intervaloSondeo = const Duration(seconds: 10),
  }) : _consultar = consultar,
       _version = version,
       super(EstadoTiempoReal<T>()) {
    _cerrar = suscribir(aplicar, _alCambiarConexion);
    refrescar();
    _programarSondeo();
  }

  final Future<T?> Function() _consultar;
  final int Function(T) _version;
  final Duration intervaloSondeo;
  late final VoidCallback _cerrar;
  Timer? _sondeo;
  bool _consultando = false;
  bool _pendiente = false;

  /// Reemplaza el estado si el nuevo es más reciente (o si no había ninguno).
  void aplicar(T nuevo) {
    if (!mounted) return;
    final actual = state.dato;
    if (actual != null && _version(nuevo) <= _version(actual)) return;
    state = state.copyWith(dato: nuevo, cargando: false, limpiarError: true);
  }

  /// Consulta por POST; también la usa la pantalla tras una acción propia.
  /// Una consulta a la vez: la que llega mientras tanto se repite al terminar,
  /// así un refresco pedido tras una acción no se pierde.
  Future<void> refrescar() async {
    if (!mounted) return;
    if (_consultando) {
      _pendiente = true;
      return;
    }
    _consultando = true;
    try {
      final r = await _consultar();
      if (!mounted) return;
      if (r != null) {
        aplicar(r);
      } else if (state.cargando) {
        state = state.copyWith(cargando: false);
      }
    } catch (e) {
      if (mounted && state.dato == null) {
        state = state.copyWith(cargando: false, error: e);
      }
    } finally {
      _consultando = false;
      if (mounted) {
        _programarSondeo();
        if (_pendiente) {
          _pendiente = false;
          unawaited(refrescar());
        }
      }
    }
  }

  void _alCambiarConexion(bool conectado) {
    if (!mounted) return;
    state = state.copyWith(conectado: conectado);
    // Al volver la conexión puede haberse perdido algún mensaje: se pide ya.
    if (conectado) refrescar();
    _programarSondeo();
  }

  /// Sondea mientras no hay conexión o todavía no llegó ningún estado (la
  /// primera consulta pudo fallar con el canal ya conectado).
  void _programarSondeo() {
    final hace = !state.conectado || state.dato == null;
    if (hace && _sondeo != null) return;
    _sondeo?.cancel();
    _sondeo = hace ? Timer.periodic(intervaloSondeo, (_) => refrescar()) : null;
  }

  @override
  void dispose() {
    _sondeo?.cancel();
    _cerrar();
    super.dispose();
  }
}
