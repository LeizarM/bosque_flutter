import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_entity.dart';

/// Columnas de `asignacion/historial` (D37). Solo lectura: asignar y quitar
/// mandan los códigos y el id, nunca la asignación completa.
class HexAsignacionModel {
  const HexAsignacionModel(this.entidad);

  final HexAsignacionEntity entidad;

  factory HexAsignacionModel.fromJson(Map<String, dynamic> j) =>
      HexAsignacionModel(
        HexAsignacionEntity(
          idAsignacion: hexBigInt(j['idAsignacion']),
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          fechaJornada: hexFecha(j['fechaJornada']),
          estado: hexTexto(j['estado']),
          estadoTexto: hexTexto(j['estadoTexto']),
          codEmpleadoAsignador: hexBigInt(j['codEmpleadoAsignador']),
          nombreAsignador: hexTexto(j['nombreAsignador']),
          motivo: hexTextoN(j['motivo']),
          fechaAsignacion: hexFecha(j['fechaAsignacion']),
          fechaQuitada: hexFecha(j['fechaQuitada']),
          codEmpleadoQuita: hexBigInt(j['codEmpleadoQuita']),
          nombreQuita: hexTextoN(j['nombreQuita']),
          cantidadReportes: hexInt(j['cantidadReportes']),
          puedeQuitar: hexBool(j['puedeQuitar']),
          totalFilas: hexInt(j['totalFilas']),
          resultado: hexTextoN(j['resultado']),
          avisoResultado: hexTextoN(j['avisoResultado']),
          textoAtrasada: hexTextoN(j['textoAtrasada']),
        ),
      );

  factory HexAsignacionModel.fromEntity(HexAsignacionEntity e) =>
      HexAsignacionModel(e);

  HexAsignacionEntity toEntity() => entidad;
}
