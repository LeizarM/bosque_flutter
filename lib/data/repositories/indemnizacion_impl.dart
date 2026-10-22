import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/indemnizacion_model.dart';
import 'package:bosque_flutter/domain/entities/indemnizacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/indemnizacion_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';

class IndemnizacionImpl extends BaseApiRepository
    implements IndemnizacionRepository {
  @override
  Future<List<IndemnizacionEntity>> listarIndemnizaciones({
    int? codEmpleado,
    String? buscar,
    String? fechaActual,
    int? codEmpresa,
    int? codArea,
    int? pagina,
    int? tamanoPagina,
  }) async {
    return await postAndReturnList<IndemnizacionEntity>(
      endpoint: AppConstants.listarIndemnizaciones,
      data: {
        'codEmpleado': codEmpleado,
        'buscar': buscar,
        'fechaActual': fechaActual,
        'codEmpresa': codEmpresa,
        'codArea': codArea,
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
      },
      fromJson: (json) => IndemnizacionModel.fromJson(json).toEntity(),
    );
  }

  @override
  Future<List<IndemnizacionEntity>> listarHistorialIndemnizaciones({
    int? codEmpleado,
    String? buscar,
    String? fechaActual,
    int? codEmpresa,
    int? codArea,
    int? pagina,
    int? tamanoPagina,
  }) async {
    return await postAndReturnList<IndemnizacionEntity>(
      endpoint: AppConstants.listarHistorialIndemnizaciones,
      data: {
        'codEmpleado': codEmpleado,
        'buscar': buscar,
        'fechaActual': fechaActual,
        'codEmpresa': codEmpresa,
        'codArea': codArea,
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
      },
      fromJson: (json) => IndemnizacionModel.fromJson(json).toEntity(),
    );
  }

  @override
  Future<Map<String, dynamic>> abmIndemnizacion({
    required IndemnizacionEntity indemnizacion,
    required int audUsuarioI,
  }) async {
    final data = IndemnizacionModel.fromEntity(indemnizacion).toJson();
    data['audUsuarioI'] = audUsuarioI;

    final response = await postAndReturnFullResponse<Map<String, dynamic>>(
      endpoint: AppConstants.abmIndemnizacion,
      data: data,
      fromJson: (json) => json,
    );
    return response;
  }

  @override
  Future<Uint8List> descargarReportePdf({
    required String endpoint,
    required Map<String, dynamic> params,
  }) async {
    return await DioClient.descargarReportePdf(
      endpoint: endpoint,
      data: params,
    );
  }

  @override
  Future<Uint8List> descargarFiniquitoExcel({
    required int codEmpleado,
    String? fechaCorte,
    String? motivoRetiro,
    String? domicilioEmpresa,
  }) async {
    return await DioClient.descargarReportePdf(
      endpoint: AppConstants.finiquitoExcel,
      data: {
        'codEmpleado': codEmpleado,
        if (fechaCorte != null && fechaCorte.isNotEmpty) 'fechaCorte': fechaCorte,
        if (motivoRetiro != null && motivoRetiro.isNotEmpty) 'motivoRetiro': motivoRetiro,
        if (domicilioEmpresa != null && domicilioEmpresa.isNotEmpty) 'domicilioEmpresa': domicilioEmpresa,
      },
    );
  }
}
