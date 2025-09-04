// To parse this JSON data, do
//
//     final tipoDuracionFormacionModel = tipoDuracionFormacionModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_duracion_formacion_entity.dart';

List<TipoDuracionFormacionModel> tipoDuracionFormacionModelFromJson(String str) => List<TipoDuracionFormacionModel>.from(json.decode(str).map((x) => TipoDuracionFormacionModel.fromJson(x)));

String tipoDuracionFormacionModelToJson(List<TipoDuracionFormacionModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoDuracionFormacionModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    TipoDuracionFormacionModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoDuracionFormacionModel.fromJson(Map<String, dynamic> json) => TipoDuracionFormacionModel(
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
    TipoDuracionFormacionEntity toEntity() => TipoDuracionFormacionEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory TipoDuracionFormacionModel.fromEntity(TipoDuracionFormacionEntity entity) => TipoDuracionFormacionModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
