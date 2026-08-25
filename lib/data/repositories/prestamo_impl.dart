import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/prestamo_model.dart';
import 'package:bosque_flutter/data/models/prestamo_detalle_model.dart';
import 'package:bosque_flutter/data/models/tipo_prestamo_model.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_prestamo_entity.dart';
import 'package:bosque_flutter/domain/repositories/prestamo_repository.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class PrestamoImpl extends BaseApiRepository implements PrestamoRepository {
  //===========================================
  // METODO PARA OBTENER LOS PRESTAMOS DESDE SAP
  //===========================================
  @override
  Future<List<PrestamoEntity>> getPrestamosSAP(
    int pagina,
    int tamanoPagina,
    int? codEmpresa,
    String? search,
    String? fechaDesde,
    String? fechaHasta,
    String? estadoFiltro,
  ) async {
    final modelos = await postAndReturnList<PrestamoModel>(
      endpoint: AppConstants.prestamoListarSAP,
      data: {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        'codEmpresa': codEmpresa,
        'search': search,
        'fechaDesde': fechaDesde,
        'fechaHasta': fechaHasta,
        'tipoEstado': estadoFiltro,
      },
      fromJson: (json) => PrestamoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<PrestamoResponse> asignarPrestamosMasivo({
    required PrestamoEntity sapRecord,
    required String xmlEmpleados,
    required String fecIniPago,
    required double numCuotas,
    required int audUsuarioI,
    required String tipoPago,
    int forzar = 0,
    String? xmlCuotas,
  }) async {
    return await postAndReturnFullResponse<PrestamoResponse>(
      endpoint: AppConstants.prestamoAsignarMasivo,
      data: {
        'codEmpresa': sapRecord.codEmpresa,
        'db': sapRecord.db,
        'transIdSAP': int.tryParse(sapRecord.numAsiento) ?? 0,
        'montoPrestamo': sapRecord.debe > 0 ? sapRecord.debe : sapRecord.haber,
        'descripcion': sapRecord.concepto,
        'fecIniPago': fecIniPago,
        'numCuotas': numCuotas,
        'xmlEmpleados': xmlEmpleados,
        'fechaDesembolso': DateFormat(
          'yyyy-MM-dd',
        ).format(sapRecord.fechaAsiento),
        'observacion': '',
        'referencia': sapRecord.referencia,
        'audUsuarioI': audUsuarioI,
        'tipoPago': tipoPago,
        'forzar': forzar,
        if (xmlCuotas != null) 'xmlCuotas': xmlCuotas,
      },
      fromJson: (json) => PrestamoResponse.fromJson(json),
    );
  }

  @override
  Future<PrestamoResponse> crearPrestamoManualMasivo({
    required int codEmpresa,
    required String db,
    required double montoPrestamo,
    required String descripcion,
    required DateTime fechaDesembolso,
    required String xmlEmpleados,
    required String fecIniPago,
    required double numCuotas,
    required int audUsuarioI,
    required String tipoPago,
    int forzar = 0,
    String? xmlCuotas,
  }) async {
    return await postAndReturnFullResponse<PrestamoResponse>(
      endpoint: AppConstants.prestamoAsignarMasivo,
      data: {
        'codEmpresa': codEmpresa,
        'db': db,
        'transIdSAP': 0,
        'montoPrestamo': montoPrestamo,
        'descripcion': descripcion,
        'fecIniPago': fecIniPago,
        'numCuotas': numCuotas,
        'xmlEmpleados': xmlEmpleados,
        'fechaDesembolso': DateFormat('yyyy-MM-dd').format(fechaDesembolso),
        'observacion': 'Préstamo Manual',
        'referencia': '',
        'audUsuarioI': audUsuarioI,
        'tipoPago': tipoPago,
        'forzar': forzar,
        if (xmlCuotas != null) 'xmlCuotas': xmlCuotas,
      },
      fromJson: (json) => PrestamoResponse.fromJson(json),
    );
  }

  @override
  Future<List<PrestamoDetalleEntity>> listarDetallesPrestamo(
    int codPrestamo,
    int mostrarAnulados,
  ) async {
    final modelos = await postAndReturnList<PrestamoDetalleModel>(
      endpoint: AppConstants.prestamoListarDetalles,
      data: {'codPrestamo': codPrestamo, 'mostrarAnulados': mostrarAnulados},
      fromJson: (json) => PrestamoDetalleModel.fromJson(json),
    );
    // Since PrestamoDetalleModel extends PrestamoDetalleEntity, we can just return it.
    return modelos;
  }

  @override
  Future<List<PrestamoDetalleEntity>> previsualizarCuotas({
    required double montoPrestamo,
    required double numCuotas,
    required String fecIniPago,
    required String tipoPago,
  }) async {
    final modelos = await postAndReturnList<PrestamoDetalleModel>(
      endpoint: AppConstants.prestamoPrevisualizarCuotas,
      data: {
        'montoPrestamo': montoPrestamo,
        'numCuotas': numCuotas,
        'fecIniPago': fecIniPago,
        'tipoPago': tipoPago,
      },
      fromJson: (json) => PrestamoDetalleModel.fromJson(json),
    );
    return modelos;
  }

  @override
  Future<List<PrestamoEntity>> listarEmpleadosAsignados({
    required int codEmpresa,
    required String db,
    required int transIdSAP,
    int? codPrestamo,
  }) async {
    final modelos = await postAndReturnList<PrestamoModel>(
      endpoint: AppConstants.prestamoListarEmpleadosAsignados,
      data: {
        'codEmpresa': codEmpresa,
        'db': db,
        'transIdSAP': transIdSAP,
        if (codPrestamo != null) 'codPrestamo': codPrestamo,
      },
      fromJson: (json) => PrestamoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<PrestamoResponse> actualizarCuotaPrestamo({
    required int codPrestDetalle,
    required String tipoPago,
    required DateTime fechaPago,
    required int audUsuario,
    String? estadoCuota,
  }) async {
    return await postAndReturnFullResponse<PrestamoResponse>(
      endpoint: AppConstants.prestamoActualizarDetalle,
      data: {
        'codPrestDetalle': codPrestDetalle,
        'tipoPago': tipoPago,
        'fechaPago': DateFormat('yyyy-MM-dd').format(fechaPago),
        'audUsuario': audUsuario,
        if (estadoCuota != null) 'estadoCuota': estadoCuota,
      },
      fromJson: (json) => PrestamoResponse.fromJson(json),
    );
  }

  @override
  Future<PrestamoResponse> adelantarCuotaPrestamo({
    required int codPrestamo,
    required double montoPago,
    required DateTime fechaPago,
    required String detalle,
    required int audUsuario,
  }) async {
    return await postAndReturnFullResponse<PrestamoResponse>(
      endpoint: AppConstants.prestamoAdelantarCuota,
      data: {
        'codPrestamo': codPrestamo,
        'montoPago': montoPago,
        'fechaPago': DateFormat('yyyy-MM-dd').format(fechaPago),
        'detalle': detalle,
        'audUsuario': audUsuario,
      },
      fromJson: (json) => PrestamoResponse.fromJson(json),
    );
  }

  @override
  Future<PrestamoResponse> editarPrestamoMasivo({
    required int codEmpresa,
    required String db,
    required int transIdSAP,
    required String xmlEmpleados,
    required int audUsuarioI,
    required double montoPrestamo,
    String? descripcion,
    DateTime? fechaDesembolso,
    int forzar = 0,
    String? xmlCuotas,
  }) async {
    return await postAndReturnFullResponse<PrestamoResponse>(
      endpoint: AppConstants.prestamoEditarMasivo,
      data: {
        'codEmpresa': codEmpresa,
        'db': db,
        'transIdSAP': transIdSAP,
        'xmlEmpleados': xmlEmpleados,
        'audUsuarioI': audUsuarioI,
        'montoPrestamo': montoPrestamo,
        if (descripcion != null) 'descripcion': descripcion,
        if (fechaDesembolso != null)
          'fechaDesembolso': DateFormat('yyyy-MM-dd').format(fechaDesembolso),
        'forzar': forzar,
        if (xmlCuotas != null) 'xmlCuotas': xmlCuotas,
      },
      fromJson: (json) => PrestamoResponse.fromJson(json),
    );
  }

  @override
  Future<String> anularPrestamo({
    required int codPrestamo,
    required int audUsuario,
  }) async {
    final response = await postAndReturnFullResponse<PrestamoResponse>(
      endpoint: AppConstants.prestamoAnular,
      data: {'codPrestamo': codPrestamo, 'audUsuarioI': audUsuario},
      fromJson: (json) => PrestamoResponse.fromJson(json),
    );
    return response.message;
  }

  @override
  Future<List<TipoPrestamoEntity>> getEstadosPrestamo() async {
    final modelos = await postAndReturnList<TipoPrestamoModel>(
      endpoint: AppConstants.prestamoEstados,
      data: {},
      fromJson: (json) => TipoPrestamoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<TipoPrestamoEntity>> getTiposPagoPrestamo() async {
    final modelos = await postAndReturnList<TipoPrestamoModel>(
      endpoint: AppConstants.prestamoTiposPago,
      data: {},
      fromJson: (json) => TipoPrestamoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Uint8List> getReporteCuotas(int codPrestamo) async {
    final response = await dio.post(
      AppConstants.prestamoReporteCuotas,
      data: {'codPrestamo': codPrestamo},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes,
      ),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('No se pudo descargar el reporte de cuotas');
    }
  }

  Future<Uint8List> _descargarReporteGlobal(String endpoint, Map<String, dynamic> params) async {
    final response = await dio.post(
      endpoint,
      data: params,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.bytes,
      ),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('No se pudo descargar el reporte');
    }
  }

  @override
  Future<Uint8List> getReportePersonal(Map<String, dynamic> params) => _descargarReporteGlobal(AppConstants.prestamoReportePersonal, params);

  @override
  Future<Uint8List> getReporteMayorGlobalResumido(Map<String, dynamic> params) => _descargarReporteGlobal(AppConstants.prestamoReporteMayorGlobalResumido, params);

  @override
  Future<Uint8List> getReporteGlobalDetallado(Map<String, dynamic> params) => _descargarReporteGlobal(AppConstants.prestamoReporteGlobalDetallado, params);

  @override
  Future<Uint8List> getReporteCortoLargoPlazo(Map<String, dynamic> params) => _descargarReporteGlobal(AppConstants.prestamoReporteCortoLargoPlazo, params);

  @override
  Future<Uint8List> getReporteMayorGeneral(Map<String, dynamic> params) => _descargarReporteGlobal(AppConstants.prestamoReporteMayorGeneral, params);
}
