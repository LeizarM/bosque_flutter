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

      // 204 = ciudad sin artículos, no es error.
      if (response.statusCode == 204 || response.data == null) {
        return [];
      }
      if (response.statusCode == 200) {
        final items =
            (response.data as List<dynamic>)
                .map((json) => ArticulosxCiudadModel.fromJson(json))
                .toList();
        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception(
          'Error al obtener artículos: Código ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // 403: pidió una ciudad que no tiene asignada (lo valida el backend).
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        throw Exception(
          data is Map && data['message'] != null
              ? data['message']
              : 'No tiene permiso para ver los precios de esa ciudad.',
        );
      }
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
