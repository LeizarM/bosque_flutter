import 'dart:convert';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Mensaje amigable de sesión inválida mostrado al usuario (nunca el crudo).
const String kSesionInvalidaMsg = 'Tu sesión expiró, inicia sesión nuevamente';

typedef AuthErrorCallback = void Function();

class DioClient {
  static AuthErrorCallback? _onAuthError;

  /// ¿Ya se avisó que no hay sesión, y todavía no volvió a haber token?
  ///
  /// Evita la tormenta de avisos cuando varias peticiones en vuelo se quedan sin
  /// token a la vez —y, sobre todo, el bucle que se produce cuando el propio
  /// callback de sesión inválida invalida providers que vuelven a pedir datos.
  /// Se re-arma en cuanto una petición encuentra token.
  static bool _sesionInvalidaAvisada = false;

  /// Por qué el backend cerró la sesión, para que el login lo muestre. Lo consume
  /// el login al abrirse y se descarta al entrar de nuevo (no en cada pedido con
  /// token: uno que leyó el token viejo en paralelo lo borraba antes de mostrarse).
  static String? _motivoCierre;

  /// El motivo del último cierre, una sola vez: lo consume la pantalla de login.
  static String? tomarMotivoCierre() {
    final motivo = _motivoCierre;
    _motivoCierre = null;
    return motivo;
  }

  /// El texto del 401 con `error: SESION_CERRADA` (JwtTokenFilter), o null si es otro 401.
  /// Los pedidos de PDF o texto plano traen el cuerpo como bytes o String: también se leen.
  static String? motivoSesionCerrada(Object? data) {
    Object? cuerpo = data;
    try {
      if (cuerpo is List<int>) cuerpo = utf8.decode(cuerpo);
      if (cuerpo is String && cuerpo.trimLeft().startsWith('{')) cuerpo = jsonDecode(cuerpo);
    } catch (_) {
      return null;
    }
    if (cuerpo is Map && cuerpo['error'] == 'SESION_CERRADA') {
      final mensaje = cuerpo['mensaje']?.toString();
      if (mensaje != null && mensaje.isNotEmpty) return mensaje;
    }
    return null;
  }

  /// Plataforma y versión de esta app, para la pantalla Sesiones del administrador.
  /// Viajan solo en el login y en el chequeo de sesión (el backend los acepta en esas rutas).
  static Map<String, String> encabezadosCliente() => {
    'X-Plataforma': _plataforma(),
    'X-Version-App': AppConstants.APP_VERSION,
  };

  static String _plataforma() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.windows => 'windows',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'desconocida',
    };
  }

  /// Avisa al backend que esta sesión terminó («Cerrar sesión»), con el token ya
  /// retirado del almacenamiento. Va por un Dio aparte y sin esperar: si falla, el
  /// token igual vence solo y la sesión queda como «sin señal».
  static void avisarSalida(String token) {
    Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {'Authorization': 'Bearer $token'},
      ),
    ).post<void>(AppConstants.salirEndpoint).catchError((Object e) {
      console('No se pudo avisar la salida al servidor: $e');
      return Response<void>(requestOptions: RequestOptions());
    });
  }

  /// Guarda el motivo si el 401 es de sesión cerrada y lo devuelve.
  static String? registrarSesionCerrada(Object? data) {
    final motivo = motivoSesionCerrada(data);
    if (motivo != null) _motivoCierre = motivo;
    return motivo;
  }

  /// Pedido mínimo para que el backend revise si la sesión sigue valiendo y anote la
  /// señal. Si ya no vale, el 401 de sesión cerrada lo resuelve onError (login con el motivo).
  static Future<void> verificarSesion() async {
    try {
      await getInstance().post<void>(
        AppConstants.sesionEndpoint,
        options: Options(headers: encabezadosCliente()),
      );
    } on DioException {
      // Sin red o backend sin el endpoint (404): se reintenta en el próximo chequeo.
    }
  }

  // 1. Instancia estática privada para el Singleton
  static Dio? _dioInstance;

  static void setAuthErrorCallback(AuthErrorCallback callback) {
    _onAuthError = callback;
  }

  // 2. Método getInstance optimizado (retorna la instancia existente)
  static Dio getInstance() {
    if (_dioInstance != null) return _dioInstance!;

    _dioInstance = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dioInstance!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Los endpoints públicos (login y recuperación de acceso) NO requieren
          // token: se dejan pasar sin leer ni adjuntar nada.
          if (options.path.contains(AppConstants.loginEndpoint) ||
              options.path.contains(AppConstants.recuperacionEndpoint)) {
            return handler.next(options);
          }
          // Las rutas del postulante de exámenes llevan su propio token
          // (DioPostulante): aquí nunca se les adjunta el del empleado.
          if (options.path.contains(AppConstants.tcpePublicoPrefijo)) {
            return handler.next(options);
          }

          final result = await SecureStorage().readTokenDetailed();
          switch (result.status) {
            case TokenReadStatus.ok:
              // Hay sesión otra vez: se re-arma el aviso de sesión inválida.
              _sesionInvalidaAvisada = false;
              options.headers['Authorization'] = 'Bearer ${result.token}';
              return handler.next(options);

            case TokenReadStatus.unavailable:
              // Fallo TRANSITORIO de lectura (cuelgue del Keystore en algunos
              // dispositivos). NO destruimos la sesión ni redirigimos al login:
              // rechazamos SOLO este request para que se pueda reintentar.
              console(
                '⚠️ No se pudo leer el token (transitorio) en ${options.path}: se rechaza el request sin cerrar sesión',
              );
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  error: 'STORAGE_NO_DISPONIBLE',
                  message:
                      'No se pudo verificar tu sesión. Inténtalo de nuevo.',
                ),
              );

            case TokenReadStatus.absent:
              // Sesión genuinamente ausente: NO enviar sin auth. Cortamos y
              // disparamos el flujo de sesión inválida (→ login).
              //
              // PERO una sola vez. El callback de sesión inválida hace
              // `ref.invalidate(...)` sobre providers que, si alguien los sigue
              // observando, Riverpod recalcula EN EL ACTO — y ese recálculo
              // dispara otra petición autenticada, que tampoco encuentra token,
              // que vuelve a llamar aquí. El bucle se veía tal cual en la consola:
              //
              //     Request a /rol-sabados/mi-equipo sin sesión: redirigiendo al login
              //     Limpiando permisos de botones
              //     Request a /rol-sabados/mi-equipo sin sesión: redirigiendo al login
              //     Limpiando permisos de botones      ...
              //
              // Y como cada vuelta ejecuta clearUser(), alcanzaba con que una
              // cayera DESPUÉS de un login exitoso para borrarle la sesión al
              // usuario recién logueado y dejarlo con el spinner del AuthGate.
              //
              // El aviso se re-arma solo en cuanto vuelve a haber token (rama
              // `ok` de arriba), así que un logout real posterior avisa igual.
              if (_sesionInvalidaAvisada) {
                console(
                  '⚠️ Request a ${options.path} sin sesión (aviso ya emitido, no se repite)',
                );
              } else {
                _sesionInvalidaAvisada = true;
                console(
                  '⚠️ Request a ${options.path} sin sesión: redirigiendo al login',
                );
                _onAuthError?.call();
              }
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  error: 'SESION_INVALIDA',
                  message: kSesionInvalidaMsg,
                ),
              );
          }
        },
        onError: (DioException e, handler) async {
          // Un 401 del postulante no es de la sesión del empleado: no la borra.
          if (e.requestOptions.path.contains(AppConstants.tcpePublicoPrefijo)) {
            return handler.next(e);
          }
          if (e.response?.statusCode == 401) {
            console('Token expirado o inválido, limpiando sesión');
            // Antes de borrar: cualquier pedido que encuentre el token ya ausente lleva
            // al login, y el login tiene que encontrar el motivo ya registrado.
            final motivo = registrarSesionCerrada(e.response?.data);
            // El token queda anulado en memoria aunque el borrado tarde o falle (Keystore
            // lento): sin esto, el router lo veía vigente y volvía al dashboard en bucle.
            SecureStorage.anularToken(_tokenDe(e.requestOptions));
            await SecureStorage().clearSession();

            if (_onAuthError != null) {
              console('Redirigiendo al login debido a token expirado');
              _onAuthError!();
            } else {
              console('No hay callback configurado para redirección al login');
            }

            // Reemplazamos el error crudo por uno amigable para la UI.
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                type: e.type,
                error: 'SESION_EXPIRADA',
                message: motivo ?? kSesionInvalidaMsg,
              ),
            );
          }
          return handler.next(e);
        },
      ),
    );

    return _dioInstance!;
  }

  /// El token con que salió el pedido (el interceptor lo puso en el encabezado).
  static String? _tokenDe(RequestOptions pedido) {
    final valor = pedido.headers['Authorization']?.toString();
    return valor != null && valor.startsWith('Bearer ') ? valor.substring(7) : null;
  }

  // 3. Centralizamos la extracción de un mensaje de error AMIGABLE.
  //    Nunca devuelve el toString() crudo de DioException ni el cuerpo HTTP.
  static String handleDioError(DioException e, String defaultMsg) {
    // 1) Mensaje estructurado del backend, si vino.
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'].toString();
      if (msg.isNotEmpty) return msg;
    }
    // 2) Mensaje amigable según el tipo de error de red.
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La conexión tardó demasiado. Revisa tu internet e inténtalo de nuevo.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor. Revisa tu conexión a internet.';
      case DioExceptionType.badCertificate:
        return 'No se pudo verificar la conexión segura con el servidor.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) {
          return motivoSesionCerrada(e.response?.data) ?? kSesionInvalidaMsg;
        }
        if (code == 403) return 'No tienes permisos para realizar esta acción.';
        if (code != null && code >= 500) {
          return 'Ocurrió un error en el servidor. Inténtalo más tarde.';
        }
        return defaultMsg;
      case DioExceptionType.cancel:
        // Los cortes por sesión inválida ya traen un mensaje amigable.
        return e.message ?? defaultMsg;
      case DioExceptionType.unknown:
        return defaultMsg;
    }
  }

  /// Baja un PDF ya armado por Jasper en el backend.
  ///
  /// [receiveTimeout] sube el tope de espera solo para este pedido. El de
  /// `BaseOptions` son 30 s, que alcanzan para un voucher pero no siempre para
  /// un reporte que recorre miles de filas: pasado ese tiempo Dio corta y el
  /// usuario ve un error de red cuando en realidad el reporte se estaba
  /// generando bien. Omitirlo deja el comportamiento de siempre.
  static Future<Uint8List> descargarReportePdf({
    required String endpoint,
    Map<String, dynamic>? data,
    Duration? receiveTimeout,
  }) async {
    final dio = getInstance(); // Ahora reutiliza la instancia

    final Response<dynamic> response;
    try {
      response = await dio.post(
        endpoint,
        data: data,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.bytes,
          receiveTimeout: receiveTimeout,
        ),
      );
    } on DioException catch (e) {
      throw Exception(mensajeDeReporteFallido(e));
    }

    if (response.statusCode == 200) {
      return response.data as Uint8List;
    } else {
      throw Exception(
        'No se pudo descargar el PDF desde $endpoint. Código: ${response.statusCode}',
      );
    }
  }

  /// El mensaje que corresponde mostrar cuando un reporte falla.
  ///
  /// **Por qué no alcanza con `handleDioError`.** Ese lee el mensaje del
  /// backend de `e.response.data['message']`, pero un reporte se pide con
  /// `responseType.bytes`: Dio no interpreta el cuerpo y el JSON de error
  /// llega como `Uint8List`, así que la comprobación `is Map` nunca da y el
  /// mensaje que el backend se tomó el trabajo de escribir —el del stored
  /// procedure, por ejemplo— se perdía. Aquí se desenvuelve primero.
  static String mensajeDeReporteFallido(DioException e) {
    final datos = e.response?.data;
    if (datos is List<int>) {
      try {
        final cuerpo = jsonDecode(utf8.decode(datos));
        if (cuerpo is Map && cuerpo['message'] != null) {
          final msg = cuerpo['message'].toString();
          if (msg.isNotEmpty) return msg;
        }
      } catch (_) {
        // No era JSON: se sigue con el mensaje por tipo de error.
      }
    }

    // El de red habla de «revisa tu internet», que aquí desorienta: el pedido
    // llegó bien y el servidor sigue trabajando; lo que se acabó es la espera.
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'El reporte tardó más de lo permitido y se canceló. '
          'Prueba acotarlo con más filtros.';
    }

    return handleDioError(e, 'No se pudo generar el reporte.');
  }
}
