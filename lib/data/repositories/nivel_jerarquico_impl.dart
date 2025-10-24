import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/nivel_jerarquico_model.dart';
import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';
import 'package:bosque_flutter/domain/repositories/nivel_jerarquico_repository.dart';
import 'package:dio/dio.dart';

class NivelJerarquicoImpl implements NivelJerarquicoRepository {
  final Dio _dio = DioClient.getInstance();

  /// Obtiene la lista de niveles jerárquicos
  @override
  Future<List<NivelJerarquicoEntity>> getNivelesJerarquicos() async {
    try {
      final response = await _dio.post(
        AppConstants.lstNivelesJerarquicos,
        data: {},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? [];
        final items =
            (data as List<dynamic>)
                .map((json) => NivelJerarquicoModel.fromJson(json))
                .toList();

        return items.map((model) => model.toEntity()).toList();
      } else {
        throw Exception('Error al obtener los niveles jerárquicos ');
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
      throw Exception(
        'Error desconocido getNivelesJerarquicos: ${e.toString()}',
      );
    }
  }
}
