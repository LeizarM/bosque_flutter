// To parse this JSON data, do
//
//     final tipoFormacionModel = tipoFormacionModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_formacion_entity.dart';

List<TipoFormacionModel> tipoFormacionModelFromJson(String str) => List<TipoFormacionModel>.from(json.decode(str).map((x) => TipoFormacionModel.fromJson(x)));

String tipoFormacionModelToJson(List<TipoFormacionModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoFormacionModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    TipoFormacionModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoFormacionModel.fromJson(Map<String, dynamic> json) => TipoFormacionModel(
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
    TipoFormacionEntity toEntity() => TipoFormacionEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory TipoFormacionModel.fromEntity(TipoFormacionEntity entity) => TipoFormacionModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
