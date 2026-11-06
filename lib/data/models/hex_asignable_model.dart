import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_asignable_entity.dart';

/// Columnas de `asignacion/asignables` (D37). Solo lectura.
class HexAsignableModel {
  const HexAsignableModel(this.entidad);

  final HexAsignableEntity entidad;

  factory HexAsignableModel.fromJson(Map<String, dynamic> j) =>
      HexAsignableModel(
        HexAsignableEntity(
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          codCargo: hexBigInt(j['codCargo']),
          cargo: hexTextoN(j['cargo']),
          codSucursal: hexBigInt(j['codSucursal']),
          nombreSucursal: hexTextoN(j['nombreSucursal']),
          fechaJornada: hexFecha(j['fechaJornada']),
          idAsignacion: hexBigInt(j['idAsignacion']),
          estaAsignado: hexBool(j['estaAsignado']),
          codEmpleadoAsignador: hexBigInt(j['codEmpleadoAsignador']),
          nombreAsignador: hexTextoN(j['nombreAsignador']),
          motivo: hexTextoN(j['motivo']),
          cantidadReportes: hexInt(j['cantidadReportes']),
          idReporte: hexBigInt(j['idReporte']),
          estadoReporte: hexTextoN(j['estadoReporte']),
          estadoReporteTexto: hexTextoN(j['estadoReporteTexto']),
          tipoAviso: hexTextoN(j['tipoAviso']),
          aviso: hexTextoN(j['aviso']),
          puedeAsignar: hexBool(j['puedeAsignar']),
          puedeQuitar: hexBool(j['puedeQuitar']),
          textoEstado: hexTexto(j['textoEstado']),
          resultado: hexTextoN(j['resultado']),
          avisoResultado: hexTextoN(j['avisoResultado']),
          textoAtrasada: hexTextoN(j['textoAtrasada']),
          fechaMinimaAsignable: hexFecha(j['fechaMinimaAsignable']),
          textoRegularizacion: hexTextoN(j['textoRegularizacion']),
        ),
      );

  factory HexAsignableModel.fromEntity(HexAsignableEntity e) =>
      HexAsignableModel(e);

  HexAsignableEntity toEntity() => entidad;
}
