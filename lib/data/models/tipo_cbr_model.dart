import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';

/// Opcion de catalogo `{ codTipos, nombre, codGrupo, listTipos }` del
/// backend. listTipos siempre llega null y no se usa.
class TipoCbrModel {
  final String codTipos;
  final String nombre;
  final int codGrupo;

  const TipoCbrModel({
    required this.codTipos,
    required this.nombre,
    required this.codGrupo,
  });

  factory TipoCbrModel.fromJson(Map<String, dynamic> json) => TipoCbrModel(
    codTipos: (json['codTipos'] ?? '').toString().trim(),
    nombre: (json['nombre'] ?? '').toString().trim(),
    codGrupo: (json['codGrupo'] as num?)?.toInt() ?? 0,
  );

  TipoCbrEntity toEntity() =>
      TipoCbrEntity(codTipos: codTipos, nombre: nombre, codGrupo: codGrupo);
}
