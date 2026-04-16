import 'dart:convert';

import 'package:bosque_flutter/domain/entities/grupo_produccion_entity.dart';

GrupoProduccionModel grupoProduccionModelFromJson(String str) =>
    GrupoProduccionModel.fromJson(json.decode(str));

String grupoProduccionModelToJson(GrupoProduccionModel data) =>
    json.encode(data.toJson());

class GrupoProduccionModel {
  final int idGrupo;
  final String grupo;
  final String descripcion;
  final int audUsuario;

  GrupoProduccionModel({
    required this.idGrupo,
    required this.grupo,
    required this.descripcion,
    required this.audUsuario,
  });

  factory GrupoProduccionModel.fromJson(Map<String, dynamic> json) =>
      GrupoProduccionModel(
        idGrupo: json["idGrupo"] ?? 0,
        grupo: json["grupo"] ?? '',
        descripcion: json["descripcion"] ?? '',
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idGrupo": idGrupo,
    "grupo": grupo,
    "descripcion": descripcion,
    "audUsuario": audUsuario,
  };

  GrupoProduccionEntity toEntity() => GrupoProduccionEntity(
    idGrupo: idGrupo,
    grupo: grupo,
    descripcion: descripcion,
    audUsuario: audUsuario,
  );

  factory GrupoProduccionModel.fromEntity(GrupoProduccionEntity entity) =>
      GrupoProduccionModel(
        idGrupo: entity.idGrupo,
        grupo: entity.grupo,
        descripcion: entity.descripcion,
        audUsuario: entity.audUsuario,
      );
}
