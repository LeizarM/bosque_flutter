// To parse this JSON data, do
//
//     final tipoSeguroModel = tipoSeguroModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_seguro_entity.dart';


List<TipoSeguroModel> tipoSeguroModelFromJson(String str) => List<TipoSeguroModel>.from(json.decode(str).map((x) => TipoSeguroModel.fromJson(x)));

String tipoSeguroModelToJson(List<TipoSeguroModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoSeguroModel {
    String codTipos;
    String nombre;
    int codGrupo;
    dynamic listTipos;

    TipoSeguroModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoSeguroModel.fromJson(Map<String, dynamic> json) => TipoSeguroModel(
        codTipos: json["codTipos"]??'',
        nombre: json["nombre"]??'',
        codGrupo: json["codGrupo"]??'',
        listTipos: json["listTipos"]??'',
    );

    Map<String, dynamic> toJson() => {
        "codTipos": codTipos,
        "nombre": nombre,
        "codGrupo": codGrupo,
        "listTipos": listTipos,
    };
    TipoSeguroEntity toEntity() => TipoSeguroEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory TipoSeguroModel.fromEntity(TipoSeguroEntity entity) => TipoSeguroModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
