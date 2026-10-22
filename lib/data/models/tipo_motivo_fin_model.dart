import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tipo_motivo_fin_entity.dart';

List<TipoMotivoFinModel> tipoMotivoFinModelFromJson(String str) =>
    List<TipoMotivoFinModel>.from(
      json.decode(str).map((x) => TipoMotivoFinModel.fromJson(x)),
    );

String tipoMotivoFinModelToJson(List<TipoMotivoFinModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoMotivoFinModel {
  final String codTipos;
  final String nombre;
  final int codGrupo;
  final dynamic listTipos;

  TipoMotivoFinModel({
    required this.codTipos,
    required this.nombre,
    required this.codGrupo,
    required this.listTipos,
  });

  factory TipoMotivoFinModel.fromJson(Map<String, dynamic> json) =>
      TipoMotivoFinModel(
        codTipos: (json["codTipos"] ?? json["codigo"] ?? '').toString().trim(),
        nombre: (json["nombre"] ?? json["descripcion"] ?? '').toString().trim(),
        codGrupo: json["codGrupo"] ?? json["grupo"] ?? 0,
        listTipos: json["listTipos"],
      );

  Map<String, dynamic> toJson() => {
    "codTipos": codTipos,
    "nombre": nombre,
    "codGrupo": codGrupo,
    "listTipos": listTipos,
  };

  TipoMotivoFinEntity toEntity() => TipoMotivoFinEntity(
    codTipos: codTipos,
    nombre: nombre,
    codGrupo: codGrupo,
    listTipos: listTipos,
  );

  factory TipoMotivoFinModel.fromEntity(TipoMotivoFinEntity entity) =>
      TipoMotivoFinModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
      );
}
