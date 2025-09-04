// To parse this JSON data, do
//
//     final estadoCivilModel = estadoCivilModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/estado_civil_entity.dart';

List<EstadoCivilModel> estadoCivilModelFromJson(String str) => List<EstadoCivilModel>.from(json.decode(str).map((x) => EstadoCivilModel.fromJson(x)));

String estadoCivilModelToJson(List<EstadoCivilModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class EstadoCivilModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    EstadoCivilModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory EstadoCivilModel.fromJson(Map<String, dynamic> json) => EstadoCivilModel(
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
    EstadoCivilEntity toEntity() => EstadoCivilEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory EstadoCivilModel.fromEntity(EstadoCivilEntity entity) => EstadoCivilModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
