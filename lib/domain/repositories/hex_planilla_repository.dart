import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/hex_planilla_anexo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';

/// Lo que RRHH elige para una planilla: empresa que paga, sucursal operativa
/// y mes. Sin empresa ni sucursal es el lote del mes (D39): todas juntas.
typedef CombinacionHex =
    ({BigInt? codEmpresa, BigInt? codSucursal, int anio, int mes});

/// El lote de [anio] y [mes]: la vista previa sin empresa ni sucursal.
CombinacionHex loteHex(int anio, int mes) => (
  codEmpresa: null,
  codSucursal: null,
  anio: anio,
  mes: mes,
);

/// Si [c] es el lote del mes y no una sola combinación.
bool esLoteHex(CombinacionHex c) =>
    c.codEmpresa == null && c.codSucursal == null;

/// Planilla de horas extra: vista previa, ejecución, consulta de lo congelado,
/// PDF y anulación. Todo es de la pantalla de RRHH; el SP valida cada caso.
abstract class HexPlanillaRepository {
  /// Planillas ejecutadas; con [idPlanilla], solo esa.
  Future<List<HexPlanillaEntity>> planillas({BigInt? idPlanilla});

  Future<List<HexPendienteEntity>> pendientes();

  Future<List<HexPrevistaEmpleadoEntity>> vistaPrevia(CombinacionHex c);

  Future<List<HexPrevistaLineaEntity>> vistaPreviaLineas(CombinacionHex c);

  Future<List<HexAvisoEntity>> avisos(CombinacionHex c);

  Future<HexRespuesta> ejecutar(CombinacionHex c, {String? observacion});

  /// D39: los reportes de [c] (o del lote) que aún no terminan de firmarse;
  /// vacía si no falta ninguno.
  Future<List<HexPlanillaFirmaEntity>> pendientesFirma(CombinacionHex c);

  /// D39: ejecuta juntas todas las combinaciones del mes; `id` es el lote.
  Future<HexRespuesta> ejecutarLote(int anio, int mes, {String? observacion});

  /// D39: anula todas las planillas del lote; la observación es obligatoria.
  Future<HexRespuesta> anularLote(BigInt idLote, String observacion);

  /// El PDF del lote, una sección por sucursal. Sin lote lanza [SinDatosHex].
  Future<Uint8List> pdfLote(BigInt idLote);

  Future<List<HexPlanillaEmpleadoEntity>> empleados(BigInt idPlanilla);

  Future<List<HexPlanillaDetalleEntity>> detalle(
    BigInt idPlanilla, {
    BigInt? codEmpleado,
  });

  Future<List<HexCodigoLeyendaEntity>> leyenda(BigInt idPlanilla);

  /// Los bytes del PDF. Si la planilla no existe lanza [SinDatosHex].
  Future<Uint8List> pdf(BigInt idPlanilla);

  Future<HexRespuesta> anular(BigInt idPlanilla, String observacion);
}
