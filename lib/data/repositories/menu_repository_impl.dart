import 'package:dio/dio.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/menu_model.dart';
import 'package:bosque_flutter/domain/entities/menu_entity.dart';
import 'package:bosque_flutter/domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<List<MenuItemEntity>> getMenuItems(int codUsuario) async {
    try {
      final response = await _dio.post(
        AppConstants.menuEndpoint, // Ajusta este endpoint según tu API
        data: {
          'codUsuario': codUsuario,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final menuModels = (response.data as List<dynamic>)
            .map((json) => MenuItemModel.fromJson(json))
            .toList();
        return menuModels.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener el menú: Código ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Manejar errores de red o del servidor
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage = 'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido: ${e.toString()}');
    }
  }
}