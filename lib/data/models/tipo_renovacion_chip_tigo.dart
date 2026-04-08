// To parse this JSON data, do
//
//     final tipoRenovacionChipModel = tipoRenovacionChipModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_renovacion_chip_tigo_entity.dart';

List<TipoRenovacionChipModel> tipoRenovacionChipModelFromJson(String str) => List<TipoRenovacionChipModel>.from(json.decode(str).map((x) => TipoRenovacionChipModel.fromJson(x)));

String tipoRenovacionChipModelToJson(List<TipoRenovacionChipModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoRenovacionChipModel {
    String codTipos;
    String nombre;
    int codGrupo;
    dynamic listTipos;

    TipoRenovacionChipModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoRenovacionChipModel.fromJson(Map<String, dynamic> json) => TipoRenovacionChipModel(
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
    TipoRenovacionChipTigoEntity toEntity() => TipoRenovacionChipTigoEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory TipoRenovacionChipModel.fromEntity(TipoRenovacionChipTigoEntity entity) => TipoRenovacionChipModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
