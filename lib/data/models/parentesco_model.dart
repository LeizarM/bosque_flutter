// To parse this JSON data, do
//
//     final parentescoModel = parentescoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/parentesco_entity.dart';

List<ParentescoModel> parentescoModelFromJson(String str) => List<ParentescoModel>.from(json.decode(str).map((x) => ParentescoModel.fromJson(x)));

String parentescoModelToJson(List<ParentescoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ParentescoModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    ParentescoModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory ParentescoModel.fromJson(Map<String, dynamic> json) => ParentescoModel(
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
    ParentescoEntity toEntity()=> ParentescoEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory ParentescoModel.fromEntity(ParentescoEntity entity) => ParentescoModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
