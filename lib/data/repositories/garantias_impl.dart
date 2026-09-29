import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/accion_cbr_model.dart';
import 'package:bosque_flutter/data/models/cbr_detalle_model.dart';
import 'package:bosque_flutter/data/models/cliente_sap_model.dart';
import 'package:bosque_flutter/data/models/garantia_cbr_model.dart';
import 'package:bosque_flutter/data/models/garantia_registro_model.dart';
import 'package:bosque_flutter/data/models/garantia_resumen_cliente_model.dart';
import 'package:bosque_flutter/data/models/garantia_vista_model.dart';
import 'package:bosque_flutter/data/models/tipo_cbr_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';
import 'package:bosque_flutter/domain/repositories/garantias_repository.dart';

/// Implementacion del modulo de garantias de cobranza contra el backend Spring.
///
/// Los helpers de BaseApiRepository resuelven el envelope, el 204 y el 400. Los
/// PDF van por DioClient.descargarReportePdf, que ademas rescata el mensaje del
/// backend cuando el reporte falla.
class GarantiasImpl extends BaseApiRepository implements GarantiasRepository {
  /// Los reportes recorren toda la tabla y cruzan con SAP: los 30 s por
  /// defecto de Dio no siempre alcanzan.
  static const Duration _esperaReporte = Duration(minutes: 2);

  // ============================ LECTURAS ===================================

  @override
  Future<List<GarantiaResumenClienteEntity>> obtenerResumenClientes({
    String? buscar,
  }) async {
    final modelos = await postAndReturnList<GarantiaResumenClienteModel>(
      endpoint: AppConstants.garantiasResumenClientes,
      data: {'buscar': _texto(buscar)},
      fromJson: GarantiaResumenClienteModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<GarantiaVistaEntity>> listarGarantias({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  }) async {
    final modelos = await postAndReturnList<GarantiaVistaModel>(
      endpoint: AppConstants.garantiasListar,
      data: _filtro(
        codClienteSAP: codClienteSAP,
        estado: estado,
        tipoGarantia: tipoGarantia,
        vencDesde: vencDesde,
        vencHasta: vencHasta,
        regDesde: regDesde,
        regHasta: regHasta,
      ),
      fromJson: GarantiaVistaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<GarantiaVistaEntity?> obtenerGarantia(BigInt codGarantia) async {
    final modelo = await postAndReturnObject<GarantiaVistaModel>(
      endpoint: AppConstants.garantiasObtener,
      data: {'id': codGarantia.toInt()},
      fromJson: GarantiaVistaModel.fromJson,
    );
    return modelo?.toEntity();
  }

  @override
  Future<List<ClienteSapEntity>> buscarClientesSap(String buscar) async {
    final modelos = await postAndReturnList<ClienteSapModel>(
      endpoint: AppConstants.garantiasClientesSap,
      data: {'buscar': buscar.trim()},
      fromJson: ClienteSapModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<CbrDetalleEntity>> obtenerDetalles(BigInt codGarantia) async {
    final modelos = await postAndReturnList<CbrDetalleModel>(
      endpoint: AppConstants.garantiasDetalles,
      data: {'id': codGarantia.toInt()},
      fromJson: CbrDetalleModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AccionCbrEntity>> obtenerAcciones(BigInt codGarantia) async {
    final modelos = await postAndReturnList<AccionCbrModel>(
      endpoint: AppConstants.garantiasAcciones,
      data: {'id': codGarantia.toInt()},
      fromJson: AccionCbrModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> contarTraspasosPendientes() async {
    // `data` es un numero suelto: postAndReturnId ya sabe leerlo.
    final n = await postAndReturnId(
      endpoint: AppConstants.garantiasTraspasosPendientes,
      data: const {},
      errorMessage: 'No se pudo consultar los traspasos pendientes',
    );
    return n.toInt();
  }

  @override
  Future<List<TipoCbrEntity>> obtenerTiposGarantia() =>
      _catalogo(AppConstants.garantiasTiposGarantia);

  @override
  Future<List<TipoCbrEntity>> obtenerEstadosAccion() =>
      _catalogo(AppConstants.garantiasEstadosAccion);

  // =========================== ESCRITURAS ==================================

  @override
  Future<BigInt> registrarGarantia(GarantiaRegistroEntity registro) =>
      postAndReturnId(
        endpoint: AppConstants.garantiasRegistrar,
        data: GarantiaRegistroModel.fromEntity(registro).toJson(),
        errorMessage: 'No se pudo guardar la garantía',
      );

  @override
  Future<BigInt> actualizarGarantia(GarantiaCbrEntity garantia) =>
      postAndReturnId(
        endpoint: AppConstants.garantiasActualizar,
        data: GarantiaCbrModel.fromEntity(garantia).toJson(),
        errorMessage: 'No se pudo actualizar la garantía',
      );

  @override
  Future<BigInt> registrarExtension({
    required BigInt codGarantia,
    required DateTime fecha,
    required String? observacion,
    required DateTime fechaExpiracion,
  }) => postAndReturnId(
    endpoint: AppConstants.garantiasExtension,
    data: {
      'codGarantia': codGarantia.toInt(),
      'fecha': fechaParaSql(fecha),
      'observacion': _texto(observacion),
      'fechaExpiracion': fechaParaSql(fechaExpiracion),
    },
    errorMessage: 'No se pudo registrar la extensión',
  );

  @override
  Future<BigInt> registrarDetalle(CbrDetalleEntity detalle) => postAndReturnId(
    endpoint: AppConstants.garantiasDetalleRegistrar,
    data: CbrDetalleModel.fromEntity(detalle).toJson(),
    errorMessage: 'No se pudo guardar el detalle',
  );

  @override
  Future<BigInt> eliminarDetalle(BigInt codDetalle) => postAndReturnId(
    endpoint: AppConstants.garantiasDetalleEliminar,
    data: {'id': codDetalle.toInt()},
    errorMessage: 'No se pudo eliminar el detalle',
  );

  @override
  Future<BigInt> registrarAccion(AccionCbrEntity accion) => postAndReturnId(
    endpoint: AppConstants.garantiasAccionRegistrar,
    data: AccionCbrModel.fromEntity(accion).toJson(),
    errorMessage: 'No se pudo guardar la acción',
  );

  @override
  Future<BigInt> eliminarAccion(BigInt codAccion) => postAndReturnId(
    endpoint: AppConstants.garantiasAccionEliminar,
    data: {'id': codAccion.toInt()},
    errorMessage: 'No se pudo eliminar la acción',
  );

  @override
  Future<int> generarTraspaso() async {
    final n = await postAndReturnId(
      endpoint: AppConstants.garantiasTraspaso,
      data: const {},
      errorMessage: 'No se pudo generar el traspaso',
    );
    return n.toInt();
  }

  // ============================ REPORTES ===================================

  @override
  Future<Uint8List> reporteRecibo(BigInt codGarantia) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.garantiasReporteRecibo,
        data: {'id': codGarantia.toInt()},
        receiveTimeout: _esperaReporte,
      );

  @override
  Future<Uint8List> reporteTraspaso() => DioClient.descargarReportePdf(
    endpoint: AppConstants.garantiasReporteTraspaso,
    data: const {},
    receiveTimeout: _esperaReporte,
  );

  @override
  Future<Uint8List> reporteBusqueda({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  }) => DioClient.descargarReportePdf(
    endpoint: AppConstants.garantiasReporteBusqueda,
    data: _filtro(
      codClienteSAP: codClienteSAP,
      estado: estado,
      tipoGarantia: tipoGarantia,
      vencDesde: vencDesde,
      vencHasta: vencHasta,
      regDesde: regDesde,
      regHasta: regHasta,
    ),
    receiveTimeout: _esperaReporte,
  );

  // ============================ PIEZAS =====================================

  Future<List<TipoCbrEntity>> _catalogo(String endpoint) async {
    final modelos = await postAndReturnList<TipoCbrModel>(
      endpoint: endpoint,
      fromJson: TipoCbrModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  /// FiltroGarantia del contrato. Las claves nulas no viajan: en el
  /// procedimiento quedan en NULL y no filtran.
  Map<String, dynamic> _filtro({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  }) {
    final m = <String, dynamic>{
      'codClienteSAP': _texto(codClienteSAP),
      'estado': _texto(estado),
      'tipoGarantia': _texto(tipoGarantia),
      'vencDesde': vencDesde == null ? null : fechaParaSql(vencDesde),
      'vencHasta': vencHasta == null ? null : fechaParaSql(vencHasta),
      'regDesde': regDesde == null ? null : fechaParaSql(regDesde),
      'regHasta': regHasta == null ? null : fechaParaSql(regHasta),
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }

  static String? _texto(String? t) =>
      (t == null || t.trim().isEmpty) ? null : t.trim();
}
