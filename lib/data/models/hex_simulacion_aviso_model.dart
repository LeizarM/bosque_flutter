import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_aviso_entity.dart';

/// Columnas de `p_list_thex_Simulacion` A. Solo lectura.
class HexSimulacionAvisoModel {
  const HexSimulacionAvisoModel(this.entidad);

  final HexSimulacionAvisoEntity entidad;

  factory HexSimulacionAvisoModel.fromJson(Map<String, dynamic> j) =>
      HexSimulacionAvisoModel(
        HexSimulacionAvisoEntity(
          orden: hexInt(j['orden']),
          nivel: hexTexto(j['nivel']),
          texto: hexTexto(j['texto']),
          queHacer: hexTextoN(j['queHacer']),
          quien: hexTextoN(j['quien']),
        ),
      );

  factory HexSimulacionAvisoModel.fromEntity(HexSimulacionAvisoEntity e) =>
      HexSimulacionAvisoModel(e);

  HexSimulacionAvisoEntity toEntity() => entidad;
}
