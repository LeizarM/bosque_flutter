import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/sesion_postulante_storage.dart';

const String kSesionPostulanteVencida =
    'Tu sesión del examen terminó. Ingresa de nuevo con tu usuario y clave.';

/// El Dio del postulante externo, aparte del de [DioClient] para que las dos
/// sesiones no se crucen: nunca adjunta el token del empleado y un 401 solo
/// cierra la sesión del postulante.
class DioPostulante {
  static Dio? _dio;
  static void Function()? _alSesionInvalida;
  static String? _motivo;

  /// Por qué el backend cortó la sesión (el `message` del 401), una sola vez:
  /// lo muestra el ingreso.
  static String? tomarMotivo() {
    final m = _motivo;
    _motivo = null;
    return m;
  }

  static String? _mensajeDe(Object? cuerpo) {
    var c = cuerpo;
    if (c is String && c.trim().startsWith('{')) {
      try {
        c = jsonDecode(c);
      } catch (_) {
        return null;
      }
    }
    final m = c is Map ? '${c['message'] ?? ''}'.trim() : '';
    return m.isEmpty ? null : m;
  }

  /// `/examen-publico/auth/**` y `/examen-publico/config` son `permitAll`
  /// en el backend: van sin token y su 401 no cierra la sesión.
  static bool esPublica(String path) =>
      path.contains(AppConstants.tcpePublicoAuthPrefijo) || path.contains(AppConstants.tcpePublicoConfig);

  /// Lo conecta el router para volver a `/examen/ingreso`.
  static void setAlSesionInvalida(void Function() callback) {
    _alSesionInvalida = callback;
  }

  static Dio instancia() {
    if (_dio != null) return _dio!;
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (esPublica(options.path)) return handler.next(options);
          final token = await SesionPostulanteStorage().tokenVigente();
          if (token == null) {
            _alSesionInvalida?.call();
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'SESION_POSTULANTE',
                message: kSesionPostulanteVencida,
              ),
            );
          }
          options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onError: (e, handler) async {
          // El 401 del login trae su motivo (mensajeIngreso): no es una sesión vencida.
          if (e.response?.statusCode == 401 && !esPublica(e.requestOptions.path)) {
            console('Token del postulante vencido o inválido');
            _motivo = _mensajeDe(e.response?.data);
            await SesionPostulanteStorage().limpiar();
            _alSesionInvalida?.call();
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                type: e.type,
                error: 'SESION_POSTULANTE',
                message: _motivo ?? kSesionPostulanteVencida,
              ),
            );
          }
          return handler.next(e);
        },
      ),
    );
    return _dio = dio;
  }
}
