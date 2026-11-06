import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_falta_entity.dart';

/// Columnas de `asignacion/faltas` (adenda D37). Solo lectura: el cuerpo
/// lleva a lo sumo `fechaDesde`, nunca la falta.
class HexAsignacionFaltaModel {
  const HexAsignacionFaltaModel(this.entidad);

  final HexAsignacionFaltaEntity entidad;

  factory HexAsignacionFaltaModel.fromJson(Map<String, dynamic> j) =>
      HexAsignacionFaltaModel(
        HexAsignacionFaltaEntity(
          idAsignacion: hexBigInt(j['idAsignacion']),
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          fechaJornada: hexFecha(j['fechaJornada']),
          resultado: hexTexto(j['resultado']),
          avisoResultado: hexTexto(j['avisoResultado']),
        ),
      );

  factory HexAsignacionFaltaModel.fromEntity(HexAsignacionFaltaEntity e) =>
      HexAsignacionFaltaModel(e);

  HexAsignacionFaltaEntity toEntity() => entidad;
}
