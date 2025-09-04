// To parse this JSON data, do
//
//     final sexoModel = sexoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/sexo_entity.dart';

List<SexoModel> sexoModelFromJson(String str) => List<SexoModel>.from(json.decode(str).map((x) => SexoModel.fromJson(x)));

String sexoModelToJson(List<SexoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SexoModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    SexoModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory SexoModel.fromJson(Map<String, dynamic> json) => SexoModel(
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
    SexoEntity toEntity() => SexoEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory SexoModel.fromEntity(SexoEntity entity) => SexoModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
