import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_opcion_entity.dart';

/// Columnas de `p_list_thex_Parametro` O: los valores de un parámetro con
/// lista. Solo lectura.
class HexParametroOpcionModel {
  const HexParametroOpcionModel(this.entidad);

  final HexParametroOpcionEntity entidad;

  factory HexParametroOpcionModel.fromJson(Map<String, dynamic> j) =>
      HexParametroOpcionModel(
        HexParametroOpcionEntity(
          valor: hexDecimal(j['valor']),
          texto: hexTexto(j['texto']),
          detalle: hexTextoN(j['detalle']),
        ),
      );

  factory HexParametroOpcionModel.fromEntity(HexParametroOpcionEntity e) =>
      HexParametroOpcionModel(e);

  HexParametroOpcionEntity toEntity() => entidad;
}
