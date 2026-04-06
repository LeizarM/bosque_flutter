import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/canales_pago_model.dart';
import 'package:bosque_flutter/data/models/cargo_pago_model.dart';
import 'package:bosque_flutter/data/models/config_comisiones_banco_model.dart';
import 'package:bosque_flutter/data/models/cotizaciones_model.dart';
import 'package:bosque_flutter/data/models/detalle_solicitud_model.dart';
import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/data/models/log_estados_model.dart';
import 'package:bosque_flutter/data/models/monedas_model.dart';
import 'package:bosque_flutter/data/models/proveedor_empresa_model.dart';
import 'package:bosque_flutter/data/models/solicitud_pago_model.dart';
import 'package:bosque_flutter/data/models/solicitud_proveedor_model.dart';
import 'package:bosque_flutter/data/models/tipos_cambio_model.dart';
import 'package:bosque_flutter/data/models/tipos_cargo_model.dart';
import 'package:bosque_flutter/data/models/tipos_transaccion_model.dart';
import 'package:bosque_flutter/data/models/transacciones_model.dart';
import 'package:bosque_flutter/domain/entities/canales_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/config_comisiones_banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cotizaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/log_estados_entity.dart';
import 'package:bosque_flutter/domain/entities/monedas_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipos_transaccion_entity.dart';
import 'package:bosque_flutter/domain/entities/transacciones_entity.dart';
import 'package:bosque_flutter/domain/repositories/pagos_extranjeros_repository.dart';

class PagosExtranjerosImpl extends BaseApiRepository
    implements PagosExtranjerosRepository {
  // ════════════════════════════════════════════════════════════════════
  // FASE 1 — Solicitud
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<BigInt> guardarSolicitudCompleta(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.guardarSolicitudCompleta,
        data: payload,
        errorMessage: 'Error al guardar la solicitud',
      );

  @override
  Future<BigInt> aprobarSolicitud(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexAprobarSolicitud,
        data: payload,
        errorMessage: 'Error al aprobar la solicitud',
      );

  // ════════════════════════════════════════════════════════════════════
  // FASE 2 — Cotización
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<BigInt> guardarCotizacionCompleta(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexGuardarCotizacion,
        data: payload,
        errorMessage: 'Error al guardar la cotización',
      );

  // ════════════════════════════════════════════════════════════════════
  // FASE 3 — Comparativa y elección
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<BigInt> aceptarCotizacion(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexAceptarCotizacion,
        data: payload,
        errorMessage: 'Error al aceptar la cotización',
      );

  @override
  Future<List<CotizacionesEntity>> getCotizacionesPorSolicitud(
    BigInt idSolicitud,
  ) async {
    final modelos = await postAndReturnList<CotizacionesModel>(
      endpoint: AppConstants.tpexObtenerCotizaciones,
      data: {'idSolicitud': idSolicitud.toInt()},
      fromJson: (json) => CotizacionesModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ════════════════════════════════════════════════════════════════════
  // FASE 4 — Transacción
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<BigInt> guardarTransaccionCompleta(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexGuardarTransaccion,
        data: payload,
        errorMessage: 'Error al guardar la transacción',
      );

  @override
  Future<BigInt> cambiarEstadoTransaccion(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexCambiarEstadoTransaccion,
        data: payload,
        errorMessage: 'Error al cambiar estado de la transacción',
      );

  @override
  Future<List<TransaccionesEntity>> getTransaccionesPorSolicitud(
    BigInt idSolicitud, {
    int codEmpresa = 0,
  }) async {
    final modelos = await postAndReturnList<TransaccionesModel>(
      endpoint: AppConstants.tpexObtenerTransaccionesSolicitud,
      data: {'idSolicitud': idSolicitud.toInt(), 'codEmpresa': codEmpresa},
      fromJson: (json) => TransaccionesModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ════════════════════════════════════════════════════════════════════
  // FASE 5 — Confirmación final
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<BigInt> confirmarPago(Map<String, dynamic> payload) => postAndReturnId(
    endpoint: AppConstants.tpexConfirmarPago,
    data: payload,
    errorMessage: 'Error al confirmar el pago',
  );

  // ════════════════════════════════════════════════════════════════════
  // Lecturas generales
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<List<EmpresaEntity>> getEmpresas() async {
    final modelos = await postAndReturnList<EmpresaModel>(
      endpoint: AppConstants.deplstEmpresas,
      fromJson: (json) => EmpresaModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ProveedorEmpresaEntity>> getProveedoresXEmpresa(
    int codEmpresa,
  ) async {
    final modelos = await postAndReturnList<ProveedorEmpresaModel>(
      endpoint: AppConstants.lstProveedoresXEmpresa,
      data: {'codEmpresa': codEmpresa},
      fromJson: (json) => ProveedorEmpresaModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<DetalleSolicitudEntity>> getFacProvYOrdCompra(
    int codEmpresa,
  ) async {
    final modelos = await postAndReturnList<DetalleSolicitudModel>(
      endpoint: AppConstants.lstFacProvYOrdCompra,
      data: {'codEmpresa': codEmpresa},
      fromJson: (json) => DetalleSolicitudModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SolicitudPagoEntity>> getSolicitudesRegistradas(
    DateTime fechaInicio,
    DateTime fechaFin,
    int codEmpresa,
  ) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final modelos = await postAndReturnList<SolicitudPagoModel>(
      endpoint: AppConstants.lstSolPagosRegistrados,
      data: {
        'fechaInicio': fmt(fechaInicio),
        'fechaFin': fmt(fechaFin),
        'codEmpresa': codEmpresa,
      },
      fromJson: (json) => SolicitudPagoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<LogEstadosEntity>> getLogPorSolicitud(BigInt idSolicitud) async {
    final modelos = await postAndReturnList<LogEstadosModel>(
      endpoint: AppConstants.tpexObtenerLogSolicitud,
      data: {'idSolicitud': idSolicitud.toInt()},
      fromJson: (json) => LogEstadosModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<LogEstadosEntity>> getLogPorTransaccion(
    BigInt idTransaccion,
  ) async {
    final modelos = await postAndReturnList<LogEstadosModel>(
      endpoint: AppConstants.tpexObtenerLogTransaccion,
      data: {'idTransaccion': idTransaccion.toInt()},
      fromJson: (json) => LogEstadosModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<LogEstadosEntity>> getTimelineSolicitud(
    BigInt idSolicitud,
  ) async {
    final modelos = await postAndReturnList<LogEstadosModel>(
      endpoint: AppConstants.tpexObtenerTimelineSolicitud,
      data: {'idSolicitud': idSolicitud.toInt()},
      fromJson: (json) => LogEstadosModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ════════════════════════════════════════════════════════════════════
  // Catálogos de lectura
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<List<CanalesPagoEntity>> getCanalesPago() async {
    final modelos = await postAndReturnList<CanalesPagoModel>(
      endpoint: AppConstants.tpexObtenerCanales,
      data: {'idCanal': 0},
      fromJson: (json) => CanalesPagoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<MonedasEntity>> getMonedas() async {
    final response = await dio.post(
      AppConstants.tpexObtenerMonedas,
      data: {'idMoneda': 0},
    );
    final raw = response.data;
    if (raw == null) return [];
    final List<dynamic> list =
        raw is List ? raw : ((raw as Map)['data'] as List<dynamic>? ?? []);
    return list
        .map((json) => MonedasModel.fromJson(json as Map<String, dynamic>))
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<List<TiposCambioEntity>> getTiposCambioPorBanco(int codBanco) async {
    final response = await dio.post(
      AppConstants.tpexObtenerTipoCambioBanco,
      data: {'codBanco': codBanco},
    );
    final raw = response.data;
    if (raw == null) return [];
    final List<dynamic> list =
        raw is List ? raw : ((raw as Map)['data'] as List<dynamic>? ?? []);
    return list
        .map((json) => TiposCambioModel.fromJson(json as Map<String, dynamic>))
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<List<TiposCargoEntity>> getTiposCargo() async {
    final modelos = await postAndReturnList<TiposCargoModel>(
      endpoint: AppConstants.tpexObtenerTiposCargo,
      data: {'idTipoCargo': 0},
      fromJson: (json) => TiposCargoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<TiposTransaccionEntity>> getTiposTransaccion() async {
    final modelos = await postAndReturnList<TiposTransaccionModel>(
      endpoint: AppConstants.tpexObtenerTiposTransaccion,
      data: {'idTipoTransaccion': 0},
      fromJson: (json) => TiposTransaccionModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ConfigComisionesBancoEntity>> getConfigComisionesPorBanco(
    int codBanco,
  ) async {
    final modelos = await postAndReturnList<ConfigComisionesBancoModel>(
      endpoint: AppConstants.tpexObtenerConfigBanco,
      data: {'codBanco': codBanco},
      fromJson: (json) => ConfigComisionesBancoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  // ════════════════════════════════════════════════════════════════════
  // Catálogos de escritura
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<BigInt> registrarCanalPago(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexRegistrarCanal,
        data: payload,
        errorMessage: 'Error al registrar canal de pago',
      );

  @override
  Future<BigInt> eliminarCanalPago(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexEliminarCanal,
        data: payload,
        errorMessage: 'Error al eliminar canal de pago',
      );

  @override
  Future<BigInt> registrarMoneda(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexRegistrarMoneda,
        data: payload,
        errorMessage: 'Error al registrar moneda',
      );

  @override
  Future<BigInt> eliminarMoneda(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexEliminarMoneda,
        data: payload,
        errorMessage: 'Error al eliminar moneda',
      );

  @override
  Future<BigInt> registrarTipoCambio(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexRegistrarTipoCambio,
        data: payload,
        errorMessage: 'Error al registrar tipo de cambio',
      );

  @override
  Future<BigInt> eliminarTipoCambio(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexEliminarTipoCambio,
        data: payload,
        errorMessage: 'Error al eliminar tipo de cambio',
      );

  @override
  Future<BigInt> registrarTipoCargo(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexRegistrarTipoCargo,
        data: payload,
        errorMessage: 'Error al registrar tipo de cargo',
      );

  @override
  Future<BigInt> eliminarTipoCargo(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexEliminarTipoCargo,
        data: payload,
        errorMessage: 'Error al eliminar tipo de cargo',
      );

  @override
  Future<BigInt> registrarTipoTransaccion(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexRegistrarTipoTransaccion,
        data: payload,
        errorMessage: 'Error al registrar tipo de transacción',
      );

  @override
  Future<BigInt> eliminarTipoTransaccion(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexEliminarTipoTransaccion,
        data: payload,
        errorMessage: 'Error al eliminar tipo de transacción',
      );

  @override
  Future<BigInt> registrarConfigComisiones(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexRegistrarConfig,
        data: payload,
        errorMessage: 'Error al registrar configuración de comisiones',
      );

  @override
  Future<BigInt> eliminarConfigComisiones(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.tpexEliminarConfig,
        data: payload,
        errorMessage: 'Error al eliminar configuración de comisiones',
      );

  // ════════════════════════════════════════════════════════════════════
  // Lecturas adicionales (spec v2)
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<List<SolicitudPagoEntity>> getObtenerSolicitudes(
    int codEmpresa,
  ) async {
    final modelos = await postAndReturnList<SolicitudPagoModel>(
      endpoint: AppConstants.tpexObtenerSolicitudes,
      data: {'codEmpresa': codEmpresa},
      fromJson: (json) => SolicitudPagoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SolicitudProveedorEntity>> getSolicitudProveedores(
    int idSolicitud,
  ) async {
    final modelos = await postAndReturnList<SolicitudProveedorModel>(
      endpoint: AppConstants.tpexObtenerSolicitudProveedor,
      data: {'idSolicitud': idSolicitud},
      fromJson: (json) => SolicitudProveedorModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<DetalleSolicitudEntity>> getDetalleSolicitud(
    int idSolicitud,
  ) async {
    final modelos = await postAndReturnList<DetalleSolicitudModel>(
      endpoint: AppConstants.tpexObtenerDetalleSolicitud,
      data: {'idSolicitud': idSolicitud},
      fromJson: (json) => DetalleSolicitudModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<CargoPagoEntity>> getCargosCotizacion(int idCotizacion) async {
    final modelos = await postAndReturnList<CargoPagoModel>(
      endpoint: AppConstants.tpexObtenerCargosCotizacion,
      data: {'idCotizacion': idCotizacion},
      fromJson: (json) => CargoPagoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TransaccionesEntity?> getTransaccion({
    required int idTransaccion,
    required int codEmpresa,
  }) async {
    final model = await postAndReturnObject<TransaccionesModel>(
      endpoint: AppConstants.tpexObtenerTransaccion,
      data: {'idTransaccion': idTransaccion, 'codEmpresa': codEmpresa},
      fromJson: (json) => TransaccionesModel.fromJson(json),
      errorMessage: 'Error al obtener la transacción',
    );
    return model?.toEntity();
  }

  @override
  Future<List<TransaccionesEntity>> getReporteTransaccionesFechas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required int codEmpresa,
  }) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final modelos = await postAndReturnList<TransaccionesModel>(
      endpoint: AppConstants.tpexReporteTransaccionesFechas,
      data: {
        'fechaInicio': fmt(fechaInicio),
        'fechaFin': fmt(fechaFin),
        'codEmpresa': codEmpresa,
      },
      fromJson: (json) => TransaccionesModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<CargoPagoEntity>> getCargosTransaccion(int idTransaccion) async {
    final modelos = await postAndReturnList<CargoPagoModel>(
      endpoint: AppConstants.tpexObtenerCargosTransaccion,
      data: {'idTransaccion': idTransaccion},
      fromJson: (json) => CargoPagoModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }
}
