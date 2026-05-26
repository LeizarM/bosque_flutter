import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/multas_model.dart';
import 'package:bosque_flutter/domain/entities/multa_entity.dart';
import 'package:bosque_flutter/domain/repositories/multa_repository.dart';

class MultaImpl extends BaseApiRepository implements MultaRepository {
  @override
  Future<List<MultaEntity>> getMultas(
    int pagina,
    int tamanoPagina,
    int? codEmpresa,
    String? search,
    int? mes,
    int? anio,
    bool soloConMulta,
  ) async {
    final modelos = await postAndReturnList<MultaModel>(
      endpoint: AppConstants.mulListasMultas,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codEmpresa': codEmpresa,
        'search': search,
        'mes': mes,
        'anio': anio,
        'soloConMulta': soloConMulta ? 1 : 0,
      },
      fromJson: (json) => MultaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<MultaResponse> generarMultas({
    required int mes,
    required int anio,
    required int audUsuarioI,
  }) async {
    final responseMap = await postAndReturnFullResponse<MultaResponse>(
      endpoint: AppConstants.mulGenerarMultas,
      data: {'mes': mes, 'anio': anio, 'audUsuarioI': audUsuarioI},
      fromJson: (json) => MultaResponse.fromJson(json),
    );
    return responseMap;
  }

  // @override
  // Future<MultaResponse> editarMulta(MultaEntity multa) async {
  //   final responseMap = await postAndReturnFullResponse<MultaResponse>(
  //     endpoint: AppConstants.mulGenerarMultas, // Usar el mismo endpoint
  //     data: {
  //       'codMulta': multa.codMulta,
  //       'codEmpleado': multa.codEmpleado,
  //       'mes': multa.mes,
  //       'anio': multa.anio,
  //       'diasTrabajados': multa.diasTrabajados,
  //       'diasMulta': multa.diasMulta,
  //       'monto': multa.monto,
  //       //'estado': multa.estado,
  //       'audUsuarioI': multa.audUsuarioI,
  //     },
  //     fromJson: (json) => MultaResponse.fromJson(json),
  //   );
  //   return responseMap;
  // }

  // NUEVO METODO PARA EDICIÓN MASIVA
  @override
  Future<MultaResponse> editarTodasMultasMasivo(
    String xmlMultas,
    int audUsuarioI,
    int mes,
    int anio,
  ) async {
    final responseMap = await postAndReturnFullResponse<MultaResponse>(
      endpoint:
          AppConstants
              .mulGenerarMultas, // Usamos el mismo endpoint inteligente de Java
      data: {
        'xmlMultas': xmlMultas,
        'audUsuarioI': audUsuarioI,
        'mes': mes, // <-- Enviamos el mes del filtro actual
        'anio': anio,
      },
      fromJson: (json) => MultaResponse.fromJson(json),
    );
    return responseMap;
  }
}
