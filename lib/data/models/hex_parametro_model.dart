import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';

/// Columnas de `p_list_thex_Parametro` L, con los textos del catálogo (D33).
/// `toJson` manda solo los parámetros de `p_abm_thex_Parametro`: el valor que
/// no se llenó no viaja.
class HexParametroModel {
  const HexParametroModel(this.entidad);

  final HexParametroEntity entidad;

  factory HexParametroModel.fromJson(Map<String, dynamic> j) =>
      HexParametroModel(
        HexParametroEntity(
          idParametro: hexBigInt(j['idParametro']),
          clave: hexTexto(j['clave']),
          valorNumero: hexDecimalN(j['valorNumero']),
          valorFecha: hexFecha(j['valorFecha']),
          leyenda: hexTexto(j['leyenda']),
          vigenteDesde: hexFecha(j['vigenteDesde']),
          vigenteHasta: hexFecha(j['vigenteHasta']),
          esVigente: hexBool(j['esVigente']),
          estadoVigencia: hexTextoN(j['estadoVigencia']),
          textoVigencia: hexTextoN(j['textoVigencia']),
          nombre: hexTextoN(j['nombre']),
          descripcion: hexTextoN(j['descripcion']),
          siFalta: hexTextoN(j['siFalta']),
          valorTexto: hexTextoN(j['valorTexto']),
          ejemplo: hexTextoN(j['ejemplo']),
          obligatorio:
              j['obligatorio'] == null ? null : hexBool(j['obligatorio']),
          puedeDejarDeUsar: hexBool(j['puedeDejarDeUsar']),
        ),
      );

  factory HexParametroModel.fromEntity(HexParametroEntity e) =>
      HexParametroModel(e);

  HexParametroEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => hexCuerpo({
    'idParametro': entidad.idParametro,
    'clave': entidad.clave,
    'valorNumero': entidad.valorNumero,
    'valorFecha': hexDiaJson(entidad.valorFecha),
    'leyenda': entidad.leyenda,
    'vigenteDesde': hexDiaJson(entidad.vigenteDesde),
  });
}
