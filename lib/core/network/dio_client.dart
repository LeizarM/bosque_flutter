import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
            debugPrint('🔑 Token expirado o inválido, limpiando sesión');
            await SecureStorage().deleteToken();
            await SecureStorage().deleteUserData();
            
            // Activar callback de error de autenticación si está configurado
            if (_onAuthError != null) {
              debugPrint('🔄 Redirigiendo al login debido a token expirado');
              _onAuthError!();
            } else {
              debugPrint('⚠️ No hay callback configurado para redirección al login');
            }
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }
}