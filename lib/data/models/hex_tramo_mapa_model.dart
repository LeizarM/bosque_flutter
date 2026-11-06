import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_mapa_entity.dart';

/// Columnas de `p_list_thex_Tramo` M (mapa del día). Solo lectura.
class HexTramoMapaModel {
  const HexTramoMapaModel(this.entidad);

  final HexTramoMapaEntity entidad;

  factory HexTramoMapaModel.fromJson(Map<String, dynamic> j) =>
      HexTramoMapaModel(
        HexTramoMapaEntity(
          tipoDia: hexTexto(j['tipoDia']),
          textoTipoDia: hexTexto(j['textoTipoDia']),
          orden: hexInt(j['orden']),
          desdeMin: hexInt(j['desdeMin']),
          hastaMin: hexInt(j['hastaMin']),
          horaDesde: hexTexto(j['horaDesde']),
          horaHasta: hexTexto(j['horaHasta']),
          clase: hexTexto(j['clase']),
          codigo: hexTextoN(j['codigo']),
          leyenda: hexTextoN(j['leyenda']),
          multiplicador: hexDecimalN(j['multiplicador']),
          esPropuesto: hexBool(j['esPropuesto']),
          texto: hexTextoN(j['texto']),
        ),
      );

  factory HexTramoMapaModel.fromEntity(HexTramoMapaEntity e) =>
      HexTramoMapaModel(e);

  HexTramoMapaEntity toEntity() => entidad;
}
