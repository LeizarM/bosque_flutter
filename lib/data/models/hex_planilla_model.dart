import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';

/// Columnas de `p_list_thex_Planilla` L. Solo lectura.
class HexPlanillaModel {
  const HexPlanillaModel(this.entidad);

  final HexPlanillaEntity entidad;

  factory HexPlanillaModel.fromJson(Map<String, dynamic> j) => HexPlanillaModel(
    HexPlanillaEntity(
      idPlanilla: hexBigInt(j['idPlanilla']),
      codEmpresa: hexBigInt(j['codEmpresa']),
      anio: hexInt(j['anio']),
      mes: hexInt(j['mes']),
      periodoTexto: hexTexto(j['periodoTexto']),
      codSucursal: hexBigInt(j['codSucursal']),
      nombreSucursal: hexTextoN(j['nombreSucursal']),
      estado: hexTexto(j['estado']),
      estadoTexto: hexTexto(j['estadoTexto']),
      fechaEjecucion: hexFecha(j['fechaEjecucion']),
      codEmpleadoEjecutor: hexBigInt(j['codEmpleadoEjecutor']),
      nombreEjecutor: hexTexto(j['nombreEjecutor']),
      totalHoras: hexDecimal(j['totalHoras']),
      totalComidas: hexDecimal(j['totalComidas']),
      total: hexDecimal(j['total']),
      cantidadEmpleados: hexInt(j['cantidadEmpleados']),
      cantidadReportes: hexInt(j['cantidadReportes']),
      motivoAnulacion: hexTextoN(j['motivoAnulacion']),
      fechaAnulacion: hexFecha(j['fechaAnulacion']),
      codEmpleadoAnulador: hexBigInt(j['codEmpleadoAnulador']),
      nombreAnulador: hexTextoN(j['nombreAnulador']),
      idLote: hexBigInt(j['idLote']),
    ),
  );

  factory HexPlanillaModel.fromEntity(HexPlanillaEntity e) =>
      HexPlanillaModel(e);

  HexPlanillaEntity toEntity() => entidad;
}
