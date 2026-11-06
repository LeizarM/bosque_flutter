import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';

/// Columnas de `p_list_thex_ConfiguracionEvento` L. Solo lectura: la bitácora
/// la escriben los SP de configuración dentro de su transacción.
class HexConfiguracionEventoModel {
  const HexConfiguracionEventoModel(this.entidad);

  final HexConfiguracionEventoEntity entidad;

  factory HexConfiguracionEventoModel.fromJson(Map<String, dynamic> j) =>
      HexConfiguracionEventoModel(
        HexConfiguracionEventoEntity(
          idEvento: hexBigInt(j['idEvento']),
          entidad: hexTexto(j['entidad']),
          entidadTexto: hexTexto(j['entidadTexto']),
          idRegistro: hexBigInt(j['idRegistro']),
          descripcion: hexTextoN(j['descripcion']),
          accion: hexTexto(j['accion']),
          accionTexto: hexTexto(j['accionTexto']),
          campo: hexTextoN(j['campo']),
          campoTexto: hexTextoN(j['campoTexto']),
          valorAnterior: hexTextoN(j['valorAnterior']),
          valorNuevo: hexTextoN(j['valorNuevo']),
          audUsuario: hexBigInt(j['audUsuario']),
          nombreUsuario: hexTextoN(j['nombreUsuario']),
          audFecha: hexFecha(j['audFecha']),
          totalFilas: hexInt(j['totalFilas']),
        ),
      );

  factory HexConfiguracionEventoModel.fromEntity(
    HexConfiguracionEventoEntity e,
  ) => HexConfiguracionEventoModel(e);

  HexConfiguracionEventoEntity toEntity() => entidad;
}
