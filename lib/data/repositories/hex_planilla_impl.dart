import 'dart:typed_data';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/data/models/hex_planilla_anexo_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_detalle_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_empleado_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_model.dart';
import 'package:bosque_flutter/data/models/hex_planilla_previa_model.dart';
import 'package:bosque_flutter/data/repositories/hex_api_base.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_anexo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';

/// Planilla de horas extra contra `/horas-extras/planilla`. Los cuerpos llevan
/// la combinación o el id de la planilla; quién ejecuta lo pone el backend.
class HexPlanillaImpl extends HexApiBase implements HexPlanillaRepository {
  @override
  Future<List<HexPlanillaEntity>> planillas({BigInt? idPlanilla}) => listar(
    AppConstants.hexPlanillaListar,
    hexCuerpo({'idPlanilla': idPlanilla}),
    (j) => HexPlanillaModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexPendienteEntity>> pendientes() => listar(
    AppConstants.hexPlanillaPendientes,
    const {},
    (j) => HexPendienteModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexPrevistaEmpleadoEntity>> vistaPrevia(CombinacionHex c) =>
      listar(
        AppConstants.hexPlanillaVistaPrevia,
        _combinacion(c),
        (j) => HexPrevistaEmpleadoModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<HexPrevistaLineaEntity>> vistaPreviaLineas(CombinacionHex c) =>
      listar(
        AppConstants.hexPlanillaVistaPreviaLineas,
        _combinacion(c),
        (j) => HexPrevistaLineaModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<HexAvisoEntity>> avisos(CombinacionHex c) => listar(
    AppConstants.hexPlanillaAvisos,
    _combinacion(c),
    (j) => HexAvisoModel.fromJson(j).toEntity(),
  );

  @override
  Future<HexRespuesta> ejecutar(CombinacionHex c, {String? observacion}) =>
      escribir(
        AppConstants.hexPlanillaEjecutar,
        _combinacion(c, observacion: observacion),
      );

  @override
  Future<List<HexPlanillaEmpleadoEntity>> empleados(BigInt idPlanilla) =>
      listar(
        AppConstants.hexPlanillaEmpleados,
        hexCuerpo({'idPlanilla': idPlanilla}),
        (j) => HexPlanillaEmpleadoModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<HexPlanillaDetalleEntity>> detalle(
    BigInt idPlanilla, {
    BigInt? codEmpleado,
  }) => listar(
    AppConstants.hexPlanillaDetalle,
    hexCuerpo({'idPlanilla': idPlanilla, 'codEmpleado': codEmpleado}),
    (j) => HexPlanillaDetalleModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<HexCodigoLeyendaEntity>> leyenda(BigInt idPlanilla) => listar(
    AppConstants.hexPlanillaLeyenda,
    hexCuerpo({'idPlanilla': idPlanilla}),
    (j) => HexCodigoLeyendaModel.fromJson(j).toEntity(),
  );

  @override
  Future<Uint8List> pdf(BigInt idPlanilla) async {
    final bytes = await descargarPdf(
      AppConstants.hexPlanillaPdf,
      hexCuerpo({'idPlanilla': idPlanilla}),
    );
    if (bytes == null) {
      throw const SinDatosHex('No se encontró la planilla para imprimir.');
    }
    return bytes;
  }

  @override
  Future<HexRespuesta> anular(BigInt idPlanilla, String observacion) =>
      escribir(
        AppConstants.hexPlanillaAnular,
        hexCuerpo({'idPlanilla': idPlanilla, 'observacion': observacion}),
      );

  @override
  Future<List<HexPlanillaFirmaEntity>> pendientesFirma(CombinacionHex c) =>
      listar(
        AppConstants.hexPlanillaPendientesFirma,
        _combinacion(c),
        (j) => HexPlanillaFirmaModel.fromJson(j).toEntity(),
      );

  @override
  Future<HexRespuesta> ejecutarLote(int anio, int mes, {String? observacion}) =>
      escribir(
        AppConstants.hexPlanillaLote,
        hexCuerpo({'anio': anio, 'mes': mes, 'observacion': observacion}),
      );

  @override
  Future<HexRespuesta> anularLote(BigInt idLote, String observacion) =>
      escribir(
        AppConstants.hexPlanillaAnularLote,
        hexCuerpo({'idLote': idLote, 'observacion': observacion}),
      );

  @override
  Future<Uint8List> pdfLote(BigInt idLote) async {
    final bytes = await descargarPdf(
      AppConstants.hexPlanillaPdf,
      hexCuerpo({'idLote': idLote}),
    );
    if (bytes == null) {
      throw const SinDatosHex('No se encontró el lote para imprimir.');
    }
    return bytes;
  }

  /// La combinación; sin empresa ni sucursal (el lote) solo viaja el mes.
  Map<String, dynamic> _combinacion(CombinacionHex c, {String? observacion}) =>
      hexCuerpo({
        'codEmpresa': c.codEmpresa,
        'codSucursal': c.codSucursal,
        'anio': c.anio,
        'mes': c.mes,
        'observacion': observacion,
      });
}
