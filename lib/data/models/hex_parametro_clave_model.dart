import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_clave_entity.dart';

/// Columnas de `p_list_thex_Parametro` K (catálogo de claves, D33). Solo
/// lectura: el catálogo vive en `fun_thex_parametroClave`.
class HexParametroClaveModel {
  const HexParametroClaveModel(this.entidad);

  final HexParametroClaveEntity entidad;

  factory HexParametroClaveModel.fromJson(Map<String, dynamic> j) =>
      HexParametroClaveModel(
        HexParametroClaveEntity(
          clave: hexTexto(j['clave']),
          nombre: hexTexto(j['nombre']),
          tipoValor: hexTexto(j['tipoValor']),
          unidad: hexTextoN(j['unidad']),
          obligatorio: hexBool(j['obligatorio']),
          descripcion: hexTextoN(j['descripcion']),
          siFalta: hexTextoN(j['siFalta']),
          tieneVigente: hexBool(j['tieneVigente']),
          aviso: hexTextoN(j['aviso']),
          conOpciones: hexBool(j['conOpciones']),
        ),
      );

  factory HexParametroClaveModel.fromEntity(HexParametroClaveEntity e) =>
      HexParametroClaveModel(e);

  HexParametroClaveEntity toEntity() => entidad;
}
