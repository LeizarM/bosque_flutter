import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/articulos_ciudad_model.dart';
import 'package:bosque_flutter/domain/entities/articulos_ciudad_entity.dart';
import 'package:bosque_flutter/domain/repositories/articulos_ciudad_repository.dart';
import 'package:dio/dio.dart';


class ArticulosCiudadImpl implements ArticulosxCiudadRepository {
  final Dio _dio = DioClient.getInstance();

  
  // obtendra una lista de artículos por ciudad
  @override
  Future<List<ArticulosxCiudadEntity>> getArticulos(int codCiudad) async {
    try {
      final response = await _dio.post(
        AppConstants.articulosEndpoint,
        data: {'codCiudad': codCiudad},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items =
            (response.data as List<dynamic>)
                .map((json) => ArticulosxCiudadModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception(
          'Error al obtener el menú: Código ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // Manejar errores de red o del servidor
      String errorMessage = 'Error de conexión: ${e.message}';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            'Error del servidor: ${e.response!.statusCode} - ${e.response!.data.toString()}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error desconocido: ${e.toString()}');
    }
  }
}
