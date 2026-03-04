// To parse this JSON data, do
//
//     final tipoEducacionModel = tipoEducacionModelFromJson(jsonString);

import 'dart:convert';


import 'package:bosque_flutter/domain/entities/tipo_educacion_entity.dart';

List<TipoEducacionModel> tipoEducacionModelFromJson(String str) => List<TipoEducacionModel>.from(json.decode(str).map((x) => TipoEducacionModel.fromJson(x)));

String tipoEducacionModelToJson(List<TipoEducacionModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoEducacionModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    TipoEducacionModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoEducacionModel.fromJson(Map<String, dynamic> json) => TipoEducacionModel(
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
    TipoEducacionEntity toEntity () => TipoEducacionEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory TipoEducacionModel.fromEntity (TipoEducacionEntity entity) => TipoEducacionModel(
        codTipos: entity.codTipos,
        nombre:  entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
