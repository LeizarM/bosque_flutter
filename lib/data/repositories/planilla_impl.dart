import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:bosque_flutter/data/models/planilla_model.dart';
import 'package:bosque_flutter/data/models/planilla_detalle_model.dart';
import 'package:bosque_flutter/domain/entities/planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/planilla_detalle_entity.dart';
import 'package:bosque_flutter/domain/repositories/planilla_repository.dart';

class PlanillaImpl extends BaseApiRepository implements PlanillaRepository {
  final Dio _dio = DioClient.getInstance();
  @override
  Future<List<PlanillaEntity>> listarPlanilla({
    required int pagina,
    required int tamanoPagina,
    int? codEmpresa,
    String? estado,
    int? filtroMes,
    int? filtroAnio,
  }) async {
    final modelos = await postAndReturnList<PlanillaModel>(
      endpoint: AppConstants.planillaListarPlanilla,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codEmpresa': codEmpresa,
        'estado': estado,
        'filtroMes': filtroMes,
        'filtroAnio': filtroAnio,
      },
      fromJson: (json) => PlanillaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<PlanillaDetalleEntity>> listarPlanillaDetalle({
    required int pagina,
    required int tamanoPagina,
    required int codPlanilla,
    String? search,
  }) async {
    final modelos = await postAndReturnList<PlanillaDetalleModel>(
      endpoint: AppConstants.planillaListarDetalle,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codPlanilla': codPlanilla,
        'search': search,
      },
      fromJson: (json) => PlanillaDetalleModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<PlanillaResponse> generarPlanilla({required int audUsuarioI}) async {
    final responseMap = await postAndReturnFullResponse<PlanillaResponse>(
      endpoint: AppConstants.planillaGenerar,
      data: {'audUsuarioI': audUsuarioI},
      fromJson: (json) => PlanillaResponse.fromJson(json),
    );
    return responseMap;
  }

  @override
  Future<PlanillaResponse> ejecutarPlanilla() async {
    final responseMap = await postAndReturnFullResponse<PlanillaResponse>(
      endpoint: AppConstants.planillaEjecutar,
      data: {},
      fromJson: (json) => PlanillaResponse.fromJson(json),
    );
    return responseMap;
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerPagosBancarios({
    required int mes,
    required int anio,
    required int codBanco,
    int? codEmpresa,
  }) async {
    final list = await postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.planillaPagosBancarios,
      data: {
        'mes': mes,
        'anio': anio,
        'codBanco': codBanco,
        'codEmpresa': codEmpresa,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return list;
  }

  Future<Uint8List> descargarEstimadoPagoBanco() async {
    final response = await _dio.post(
      AppConstants.planillaPdfEstimadoPagoBanco,
      data: {},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes,
      ),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('No se pudo descargar el PDF');
    }
  }

  Future<Uint8List> descargarPlanillaCompacta(int codPlanilla) async {
    final response = await _dio.post(
      AppConstants.planillaPdfCompacta,
      data: {'codPlanilla': codPlanilla},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes,
      ),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('No se pudo descargar el PDF');
    }
  }

  Future<Uint8List> descargarPlanillaExtendida(int codPlanilla) async {
    final response = await _dio.post(
      AppConstants.planillaPdfExtendida,
      data: {'codPlanilla': codPlanilla},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes,
      ),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('No se pudo descargar el PDF');
    }
  }
}
