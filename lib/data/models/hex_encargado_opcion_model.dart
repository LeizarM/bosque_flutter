import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_encargado_opcion_entity.dart';

/// Columnas de `p_list_thex_Aprobador` E: los encargados para elegir. Solo
/// lectura; `toJson` existe por la paridad de modelos.
class HexEncargadoOpcionModel {
  const HexEncargadoOpcionModel(this.entidad);

  final HexEncargadoOpcionEntity entidad;

  factory HexEncargadoOpcionModel.fromJson(Map<String, dynamic> j) =>
      HexEncargadoOpcionModel(
        HexEncargadoOpcionEntity(
          codEmpleado: hexBigInt(j['codEmpleado']),
          nombreEmpleado: hexTexto(j['nombreEmpleado']),
          cargo: hexTextoN(j['cargo']),
          cantidadRama: hexInt(j['cantidadRama']),
          jefesActuales: hexTextoN(j['jefesActuales']),
        ),
      );

  factory HexEncargadoOpcionModel.fromEntity(HexEncargadoOpcionEntity e) =>
      HexEncargadoOpcionModel(e);

  HexEncargadoOpcionEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => hexCuerpo({
    'codEmpleado': entidad.codEmpleado,
    'nombreEmpleado': entidad.nombreEmpleado,
    'cargo': entidad.cargo,
    'cantidadRama': entidad.cantidadRama,
    'jefesActuales': entidad.jefesActuales,
  });
}
