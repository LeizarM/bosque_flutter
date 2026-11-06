import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_requisito_marca_entity.dart';

/// Columnas de `p_list_thex_Reporte` S. Solo lectura: `toJson` existe por la
/// regla de paridad, pero ningún endpoint manda un requisito.
class HexRequisitoMarcaModel {
  const HexRequisitoMarcaModel(this.entidad);

  final HexRequisitoMarcaEntity entidad;

  factory HexRequisitoMarcaModel.fromJson(Map<String, dynamic> j) =>
      HexRequisitoMarcaModel(
        HexRequisitoMarcaEntity(
          requisito: hexTexto(j['requisito']),
          cumple: hexBool(j['cumple']),
          bloquea: hexBool(j['bloquea']),
          titulo: hexTexto(j['titulo']),
          detalle: hexTexto(j['detalle']),
          orden: hexInt(j['orden']),
        ),
      );

  factory HexRequisitoMarcaModel.fromEntity(HexRequisitoMarcaEntity e) =>
      HexRequisitoMarcaModel(e);

  HexRequisitoMarcaEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => {
    'requisito': entidad.requisito,
    'cumple': entidad.cumple,
    'bloquea': entidad.bloquea,
    'titulo': entidad.titulo,
    'detalle': entidad.detalle,
    'orden': entidad.orden,
  };
}
