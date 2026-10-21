import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/nivel_jerarquico_model.dart';
import 'package:bosque_flutter/data/models/resultado_escritura_model.dart';
import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/repositories/nivel_jerarquico_repository.dart';
import 'package:dio/dio.dart';

class NivelJerarquicoImpl extends BaseApiRepository
    implements NivelJerarquicoRepository {
  final Dio _dio = DioClient.getInstance();

  @override
  Future<List<NivelJerarquicoEntity>> listarEscalas() async {
    final modelos = await postAndReturnList<NivelJerarquicoModel>(
      endpoint: AppConstants.nivelJerarquicoListar,
      fromJson: NivelJerarquicoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ResultadoEscrituraEntity> registrar(NivelJerarquicoEntity escala) =>
      _escribir(
        AppConstants.nivelJerarquicoRegistrar,
        NivelJerarquicoModel.fromEntity(escala).toJson(),
      );

  @override
  Future<ResultadoEscrituraEntity> eliminar(int codNivel) =>
      _escribir(AppConstants.nivelJerarquicoEliminar, {'id': codNivel});

  /// El texto de éxito o de error lo redacta `p_abm_NivelJerarquico`.
  Future<ResultadoEscrituraEntity> _escribir(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final modelo = await postAndReturnFullResponse<ResultadoEscrituraModel>(
      endpoint: endpoint,
      data: data,
      fromJson: ResultadoEscrituraModel.fromJson,
    );
    return modelo.toEntity();
  }

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
