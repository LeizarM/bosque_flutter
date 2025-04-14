import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/articulos_almacen_model.dart';
import 'package:dio/dio.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/domain/entities/articulos_almacen_entity.dart';
import 'package:bosque_flutter/domain/repositories/articulos_almacen_repository.dart';

class ArticulosAlmacenImpl implements ArticulosxAlmacenRepository {
  
  
  final Dio _dio = DioClient.getInstance();
  
  
  
  // Metodo para obtener artículos de almacen
  @override
  Future<List<ArticulosxAlmacenEntity>> getArticulosXAlmacen(
    String codArticulo,
    int codCiudad,
  ) async {
   
    try {
      final response = await _dio.post(
        AppConstants.articulosAlmacenEndpoint,
        data: {
          'codArticulo': codArticulo,
          'codCiudad': codCiudad,
        },
      );

      if(response.statusCode == 200 && response.data != null) {
      
        final items = (response.data as List<dynamic>)
            .map((json) => ArticulosxAlmacenModel.fromJson(json))
            .toList();
        return items.map((model) => model.toEntity()).toList();
      }else{
        throw Exception('Error al obtener artículos de almacen');
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
