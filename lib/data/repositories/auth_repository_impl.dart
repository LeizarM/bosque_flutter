import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:bosque_flutter/data/models/login_model.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';


class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<(LoginEntity?, String)> login(String username, String password) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {
          'login': username,
          'password2': password,
        },
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
}