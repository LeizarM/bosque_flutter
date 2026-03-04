import 'dart:typed_data';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:dio/dio.dart';

typedef AuthErrorCallback = void Function();

class DioClient {
  static AuthErrorCallback? _onAuthError;

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
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dioInstance!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage().getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            console('oken expirado o inválido, limpiando sesión');
            await SecureStorage().deleteToken();
            await SecureStorage().deleteUserData();

            if (_onAuthError != null) {
              console('Redirigiendo al login debido a token expirado');
              _onAuthError!();
            } else {
              console('No hay callback configurado para redirección al login');
            }
          }
          return handler.next(e);
        },
      ),
    );

    return _dioInstance!;
  }

  // 3. Centralizamos la extracción del mensaje de error
  static String handleDioError(DioException e, String defaultMsg) {
    if (e.response?.data is Map) {
      return e.response!.data['message'] ?? 'Error de red';
    }
    return 'Error de conexión: ${e.message}';
  }

  static Future<Uint8List> descargarReportePdf({
    required String endpoint,
    Map<String, dynamic>? data,
  }) async {
    final dio = getInstance(); // Ahora reutiliza la instancia

    final response = await dio.post(
      endpoint,
      data: data,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes,
      ),
    );

    if (response.statusCode == 200) {
      return response.data as Uint8List;
    } else {
      throw Exception(
        'No se pudo descargar el PDF desde $endpoint. Código: ${response.statusCode}',
      );
    }
  }
}
