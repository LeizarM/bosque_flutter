import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';


class DioClient {
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
            // Token expirado o inválido, redirigir al login
            await SecureStorage().deleteToken();
            // Aquí puedes usar Navigator para redirigir al login
            // Esto requiere un contexto global o un callback, lo configuraremos más adelante
            debugPrint('Token expirado, redirigiendo al login');
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }
}