import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';

/// Columnas de `p_list_thex_Tramo` L y V. `toJson` manda solo los parámetros de
/// `p_abm_thex_Tramo`, sin auditoría; las horas viajan como `HH:mm:ss`.
class HexTramoModel {
  const HexTramoModel(this.entidad);

  final HexTramoEntity entidad;

  factory HexTramoModel.fromJson(Map<String, dynamic> j) => HexTramoModel(
    HexTramoEntity(
      idTramo: hexBigInt(j['idTramo']),
      codigo: hexTexto(j['codigo']),
      leyenda: hexTexto(j['leyenda']),
      tipoDia: hexTexto(j['tipoDia']),
      horaDesde: hexHoraN(j['horaDesde']),
      horaHasta: hexHoraN(j['horaHasta']),
      multiplicador: hexDecimal(j['multiplicador']),
      orden: hexIntN(j['orden']),
      vigenteDesde: hexFecha(j['vigenteDesde']),
      vigenteHasta: hexFecha(j['vigenteHasta']),
      audUsuario: hexBigInt(j['audUsuario']),
      audFecha: hexFecha(j['audFecha']),
      esVigente: hexBool(j['esVigente']),
      estadoVigencia: hexTextoN(j['estadoVigencia']),
      textoVigencia: hexTextoN(j['textoVigencia']),
    ),
  );

  factory HexTramoModel.fromEntity(HexTramoEntity e) => HexTramoModel(e);

  HexTramoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => hexCuerpo({
    'idTramo': entidad.idTramo,
    'codigo': entidad.codigo,
    'leyenda': entidad.leyenda,
    'tipoDia': entidad.tipoDia,
    'horaDesde': hexHoraN(entidad.horaDesde),
    'horaHasta': hexHoraN(entidad.horaHasta),
    'multiplicador': entidad.multiplicador,
    'orden': entidad.orden,
    'vigenteDesde': hexDiaJson(entidad.vigenteDesde),
  });
}
