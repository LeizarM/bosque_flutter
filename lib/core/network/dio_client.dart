import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:dio/dio.dart';

// Callback global para redirección al login cuando el token expira
typedef AuthErrorCallback = void Function();
AuthErrorCallback? _onAuthError;

class DioClient {
  // Método para establecer el callback de error de autenticación
  static void setAuthErrorCallback(AuthErrorCallback callback) {
    _onAuthError = callback;
  }

  static Dio getInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Obtener el token almacenado
          final token = await SecureStorage().getToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Manejo global de errores
          if (e.response?.statusCode == 401) {
            // Token expirado o inválido
            console('🔑 Token expirado o inválido, limpiando sesión');
            await SecureStorage().deleteToken();
            await SecureStorage().deleteUserData();

            // Activar callback de error de autenticación si está configurado
            if (_onAuthError != null) {
              console('🔄 Redirigiendo al login debido a token expirado');
              _onAuthError!();
            } else {
              console(
                '⚠️ No hay callback configurado para redirección al login',
              );
            }
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  //FUNCION PARA DESCARGAR EL PDF
  static Future<Uint8List> descargarReportePdf({
    required String endpoint, // URL específica del reporte
    Map<String, dynamic>? data, // Opcional: parámetros para el body
  }) async {
    // 1. Obtenemos la instancia de Dio para asegurar que se usen los interceptores
    final dio = getInstance();

    final response = await dio.post(
      endpoint,
      data: data,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes, // Esencial para recibir el archivo
      ),
    );

    if (response.statusCode == 200) {
      // El cast es seguro si responseType es bytes
      return response.data as Uint8List;
    } else {
      throw Exception(
        'No se pudo descargar el PDF desde $endpoint. Código: ${response.statusCode}',
      );
    }
  }
}
