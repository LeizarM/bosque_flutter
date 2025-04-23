import 'package:dio/dio.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:bosque_flutter/data/models/login_model.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<(LoginEntity?, String)> login(String username, String password) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'login': username, 'password2': password},
      );
      final loginModel = LoginModel.fromJson(response.data);
      if (loginModel.status == 'success' && loginModel.data != null) {
        // Guardar el token si el login es exitoso
        await SecureStorage().saveToken(loginModel.data!.token);
        return (loginModel.toEntity(), loginModel.mensaje);
      } else {
        // Devolver el mensaje de error del backend
        return (null, loginModel.mensaje);
      }
    } on DioException catch (e) {
      // Manejar errores de red o del servidor
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        final errorModel = LoginModel.fromJson(e.response!.data);
        errorMessage = errorModel.mensaje;
      }
      return (null, errorMessage);
    } catch (e) {
      return (null, 'Error desconocido: ${e.toString()}');
    }
  }

  /// Método para obtener los usuarios
  @override
  @override
  Future<List<LoginEntity>> getUsers() async {
    try {
      final response = await _dio.post(AppConstants.usuariosEndPoint, data: {});

      if (response.statusCode == 200 && response.data != null) {
        final items =
            (response.data as List<dynamic>)
                .map((json) => LoginEntity.fromJson(json))
                .toList();

        return items;
      } else {
        throw Exception('Error al obtener los usuarios');
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido en getUser(): ${e.toString()}');
    }
  }

  /// Método para restablecer la contraseña de un usuario
  @override
  Future<bool> changePassword(LoginEntity user) async {
    try {
      final data = user.toJson();
      // Endpoint para marcar todo el documento como entregado
      try {
        final response = await _dio.post(
          AppConstants.changePasswordEndPoint,
          data: data,
        );

        return response.statusCode == 200 || response.statusCode == 201;
      } on DioException catch (e) {
        if (e.response != null) {
          debugPrint('CÓDIGO DE ESTADO: ${e.response?.statusCode}');
          debugPrint('DATOS DE RESPUESTA: ${e.response?.data}');
        }
        if (e.error != null) {
          debugPrint('ERROR DETALLADO: ${e.error}');
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error desconocido al marcar documento: ${e.toString()}');
      // Intentamos guardar localmente para sincronizar después

      return false;
    }
  }
}
