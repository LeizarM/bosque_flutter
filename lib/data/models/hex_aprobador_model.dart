import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';

/// Columnas de `p_list_thex_Aprobador` L. `toJson` manda solo los parámetros de
/// `p_abm_thex_Aprobador`; quien asigna lo pone el backend desde el token.
class HexAprobadorModel {
  const HexAprobadorModel(this.entidad);

  final HexAprobadorEntity entidad;

  factory HexAprobadorModel.fromJson(Map<String, dynamic> j) =>
      HexAprobadorModel(
        HexAprobadorEntity(
          idAprobador: hexBigInt(j['idAprobador']),
          codEmpleadoAprobador: hexBigInt(j['codEmpleadoAprobador']),
          nombreAprobador: hexTexto(j['nombreAprobador']),
          nivel: hexInt(j['nivel']),
          nivelTexto: hexTexto(j['nivelTexto']),
          codCargo: hexBigInt(j['codCargo']),
          cargo: hexTextoN(j['cargo']),
          cantidadRama: hexInt(j['cantidadRama']),
          avisoCargo: hexTextoN(j['avisoCargo']),
          codEmpleadoAprobado: hexBigInt(j['codEmpleadoAprobado']),
          nombreAprobado: hexTextoN(j['nombreAprobado']),
          textoAlcance: hexTextoN(j['textoAlcance']),
          vigenteDesde: hexFecha(j['vigenteDesde']),
          vigenteHasta: hexFecha(j['vigenteHasta']),
          esVigente: hexBool(j['esVigente']),
          aprobadorActivo: hexBool(j['aprobadorActivo']),
          audUsuario: hexBigInt(j['audUsuario']),
          audFecha: hexFecha(j['audFecha']),
        ),
      );

  factory HexAprobadorModel.fromEntity(HexAprobadorEntity e) =>
      HexAprobadorModel(e);

  HexAprobadorEntity toEntity() => entidad;

  /// Sin sucursal (D34). En nivel 2 y 3 van los encargados que aprueba u
  /// observa (D35, D45), como enteros; vacío no viaja y el backend responde 400.
  Map<String, dynamic> toJson() => hexCuerpo({
    'idAprobador': entidad.idAprobador,
    'codEmpleadoAprobador': entidad.codEmpleadoAprobador,
    'nivel': entidad.nivel,
    'codEmpleadosAprobados':
        entidad.codEmpleadosAprobados.isEmpty
            ? null
            : [for (final c in entidad.codEmpleadosAprobados) c.toInt()],
    'vigenteDesde': hexDiaJson(entidad.vigenteDesde),
    'vigenteHasta': hexDiaJson(entidad.vigenteHasta),
  });
}
