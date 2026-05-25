import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/anticipo_detalle_model.dart';
import 'package:bosque_flutter/data/models/anticipo_model.dart';
import 'package:bosque_flutter/data/models/anticipo_preview_model.dart';
import 'package:bosque_flutter/domain/entities/anticipo_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/domain/repositories/anticipo_repository.dart';

class AnticipoImpl extends BaseApiRepository implements AnticipoRepository {
  //===========================================
  //METODO PARA OBTENER LOS ANTICIPOS DESDE SAP
  //===========================================
  @override
  Future<List<AnticipoEntity>> getAnticiposSAP(
    int pagina,
    int tamanoPagina,
    int codEmpresa,
    String? search,
    String? mes, // Nuevo
    String? anio, // Nuevo
  ) async {
    final modelos = await postAndReturnList<AnticipoModel>(
      endpoint: AppConstants.antListarAnticipoSAP,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codEmpresa': codEmpresa,
        'search': search,
        'mes': mes,
        'anio': anio,
      },
      fromJson: (json) => AnticipoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  //===========================================
  //METODO PARA OBTENER LOS ANTICIPOS DESDE SAP
  //===========================================
  @override
  Future<List<AnticipoEntity>> getAnticiposBosque(
    int pagina,
    int tamanoPagina,
    int codEmpresa,
    String? search,
    String? estado,
  ) async {
    final modelos = await postAndReturnList<AnticipoModel>(
      endpoint: AppConstants.antListarAnticiposBosque,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codEmpresa': codEmpresa,
        'search': search,
        'estado': estado,
      },
      fromJson: (json) => AnticipoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  //===========================================
  //METODO PARA OBTENER LOS ANTICIPOS DETALLADOS EN BOSQUE
  //===========================================
  @override
  Future<List<AnticipoDetalleEntity>> getAnticipoDetallado(
    int codAnticipo,
    int? pagina,
    int? tamanoPagina,
    String? search,
  ) async {
    final modelos = await postAndReturnList<AnticipoDetalleModel>(
      endpoint: AppConstants.antListarAnticipoDetallado,
      data: {
        'codAnticipo': codAnticipo,
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'search': search,
      },
      fromJson: (json) => AnticipoDetalleModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  //===========================================
  //LISTA UNIFICADA ANTICIPOS BOSQUE - SAP
  //===========================================
  @override
  Future<List<AnticipoEntity>> getAnticipos(
    int pagina,
    int tamanoPagina,
    int? codEmpresa,
    String? search,
    String? estado,
    String? mes,
    String? anio,
  ) async {
    final modelos = await postAndReturnList<AnticipoModel>(
      endpoint: AppConstants.antAnticiposUnificados,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codEmpresa': codEmpresa,
        'search': search,
        'estado': estado,
        'mes': mes,
        'anio': anio,
      },
      fromJson: (json) => AnticipoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  //===========================================
  //OBTENER LISTA DE ANTICIPOS NO ASIGNADOS
  //===========================================
  @override
  Future<List<AnticipoDetalleEntity>> getAnticipoDetalleNoAsignado(
    int pagina,
    int tamanoPagina,
    int codEmpresa,
    String? search,
    int? codAnticipo,
  ) async {
    final modelos = await postAndReturnList<AnticipoDetalleModel>(
      endpoint: AppConstants.antAnticipoNoAsignado,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codEmpresa': codEmpresa,
        'search': search,
        'codAnticipo': codAnticipo,
      },
      fromJson: (json) => AnticipoDetalleModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  // Agregar al final de AnticipoImpl, antes del cierre de la clase:

  //===========================================
  // REGISTRAR / VINCULAR ANTICIPO SAP CON DETALLES TIGO
  // Llama a p_abm_Anticipo ACCION='I' con @xmlDetalles
  //===========================================
  //===========================================
  // REGISTRAR / VINCULAR ANTICIPO SAP CON DETALLES TIGO
  //===========================================
  @override
  Future<AnticipoResponse> asignarAnticipo({
    required AnticipoEntity cabecera,
    required List<int> codAntDetalles,
    required int audUsuarioI,
  }) async {
    final buffer = StringBuffer('<detalles>');
    for (final id in codAntDetalles) {
      buffer.write('<detalle codAntDetalle="$id" />');
    }
    buffer.write('</detalles>');
    final xmlDetalles = buffer.toString();

    return await postAndReturnFullResponse<AnticipoResponse>(
      endpoint: AppConstants.antRegistrarAnticipo,
      data: {
        'codEmpresa': cabecera.codEmpresa,
        'db': cabecera.db,
        'codigoCuenta': cabecera.codigoCuenta,
        'nombreCuenta': cabecera.nombreCuenta,
        'fechaAsiento':
            '${cabecera.fechaAsiento.year}-${cabecera.fechaAsiento.month.toString().padLeft(2, '0')}-${cabecera.fechaAsiento.day.toString().padLeft(2, '0')}',
        'numAsiento': cabecera.numAsiento,
        'concepto': cabecera.concepto,
        'referencia': cabecera.referencia,
        'debe': cabecera.debe,
        'haber': cabecera.haber,
        'audUsuarioI': audUsuarioI,
        'moduloOrigen': 'TIGO',
        'xmlDetalles': xmlDetalles,
      },
      fromJson: (json) => AnticipoResponse.fromJson(json),
    );
  }

  //===========================================
  // PREVISUALIZAR ASIGNACIÓN MANUAL (ACCION = 'P')
  //===========================================
  @override
  Future<List<AnticipoPreviewEntity>> previsualizarAsignacion({
    required AnticipoEntity cabecera,
    required String xmlEmpleados,
  }) async {
    final modelos = await postAndReturnList<AnticipoPreviewEntity>(
      endpoint: AppConstants.antPrevisualizarAsignacion,
      data: {
        'codEmpresa': cabecera.codEmpresa,
        'debe': cabecera.debe,
        'xmlEmpleados': xmlEmpleados,
        // ✅ Agregar los campos que el SP valida:
        'numAsiento': cabecera.numAsiento,
        'fechaAsiento':
            '${cabecera.fechaAsiento.year}-'
            '${cabecera.fechaAsiento.month.toString().padLeft(2, '0')}-'
            '${cabecera.fechaAsiento.day.toString().padLeft(2, '0')}',
        'audUsuarioI': cabecera.audUsuario,
      },
      fromJson: (json) => AnticipoPreviewModel.fromJson(json),
    );
    return modelos;
  }

  //===========================================
  // REGISTRAR ASIGNACIÓN MANUAL (ACCION = 'I')
  //===========================================
  @override
  Future<AnticipoResponse> asignarAnticipoManual({
    required AnticipoEntity cabecera,
    required String xmlEmpleados,
    required int audUsuarioI,
  }) async {
    return await postAndReturnFullResponse<AnticipoResponse>(
      endpoint: AppConstants.antRegistrarAnticipo,
      data: {
        'codEmpresa': cabecera.codEmpresa,
        'db': cabecera.db,
        'codigoCuenta': cabecera.codigoCuenta,
        'nombreCuenta': cabecera.nombreCuenta,
        'fechaAsiento':
            '${cabecera.fechaAsiento.year}-${cabecera.fechaAsiento.month.toString().padLeft(2, '0')}-${cabecera.fechaAsiento.day.toString().padLeft(2, '0')}',
        'numAsiento': cabecera.numAsiento,
        'concepto': cabecera.concepto,
        'referencia': cabecera.referencia,
        'debe': cabecera.debe,
        'haber': cabecera.haber,
        'audUsuarioI': audUsuarioI,
        'moduloOrigen': 'MANUAL',
        'xmlEmpleados': xmlEmpleados,
      },
      fromJson: (json) => AnticipoResponse.fromJson(json),
    );
  }

  //===========================================
  // ANULAR ANTICIPO
  //===========================================
  @override
  Future<AnticipoResponse> anularAnticipo({
    required int codAnticipo,
    required int audUsuarioI,
  }) async {
    return await postAndReturnFullResponse<AnticipoResponse>(
      endpoint: AppConstants.antAnularAnticipo,
      data: {'codAnticipo': codAnticipo, 'audUsuarioI': audUsuarioI},
      fromJson: (json) => AnticipoResponse.fromJson(json),
    );
  }

  //===========================================
  // EDITAR ASIGNACIÓN MANUAL (ACCION = 'M')
  //===========================================
  @override
  Future<AnticipoResponse> editarAsignacionManual({
    required AnticipoEntity cabecera,
    required String xmlEmpleados,
    required int audUsuarioI,
  }) async {
    return await postAndReturnFullResponse<AnticipoResponse>(
      endpoint: AppConstants.antEditarAsignacion,
      data: {
        'codAnticipo': cabecera.codAnticipo,
        'codEmpresa': cabecera.codEmpresa,
        'audUsuarioI': audUsuarioI,
        'xmlEmpleados': xmlEmpleados,
      },
      fromJson: (json) => AnticipoResponse.fromJson(json),
    );
  }

  @override
  Future<List<String>> estadoAnticipo(int codAnticipo) async {
    final response = await postAndReturnList<String>(
      endpoint: AppConstants.antEstadoAnticipo,
      data: {'codAnticipo': codAnticipo},
      fromJson: (json) => json['estadoAnticipo'] as String,
    );
    return response;
  }
}
