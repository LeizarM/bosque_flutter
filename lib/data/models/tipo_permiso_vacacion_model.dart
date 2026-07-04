import 'dart:convert';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';

List<TipoPermisoVacacionModel> tipoEducacionModelFromJson(String str) =>
    List<TipoPermisoVacacionModel>.from(
      json.decode(str).map((x) => TipoPermisoVacacionModel.fromJson(x)),
    );

String tipoEducacionModelToJson(List<TipoPermisoVacacionModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoPermisoVacacionModel {
  final String codTipos;
  final String nombre;
  final int codGrupo;
  final dynamic listTipos;

  TipoPermisoVacacionModel({
    required this.codTipos,
    required this.nombre,
    required this.codGrupo,
    required this.listTipos,
  });

  factory TipoPermisoVacacionModel.fromJson(Map<String, dynamic> json) =>
      TipoPermisoVacacionModel(
        codTipos: json["codTipos"],
        nombre: json["nombre"],
        codGrupo: json["codGrupo"],
        listTipos: json["listTipos"],
      );

  Map<String, dynamic> toJson() => {
    "codTipos": codTipos,
    "nombre": nombre,
    "codGrupo": codGrupo,
    "listTipos": listTipos,
  };
  TipoPermisoVacacionEntity toEntity() => TipoPermisoVacacionEntity(
    codTipos: codTipos,
    nombre: nombre,
    codGrupo: codGrupo,
    listTipos: listTipos,
  );
  factory TipoPermisoVacacionModel.fromEntity(
    TipoPermisoVacacionEntity entity,
  ) => TipoPermisoVacacionModel(
    codTipos: entity.codTipos,
    nombre: entity.nombre,
    codGrupo: entity.codGrupo,
    listTipos: entity.listTipos,
  );
}
