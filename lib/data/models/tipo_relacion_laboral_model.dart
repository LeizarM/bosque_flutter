// To parse this JSON data, do
//
//     final tipoRelacionLaboralModel = tipoRelacionLaboralModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_relacion_laboral_entity.dart';

List<TipoRelacionLaboralModel> tipoRelacionLaboralModelFromJson(String str) => List<TipoRelacionLaboralModel>.from(json.decode(str).map((x) => TipoRelacionLaboralModel.fromJson(x)));

String tipoRelacionLaboralModelToJson(List<TipoRelacionLaboralModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoRelacionLaboralModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    TipoRelacionLaboralModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoRelacionLaboralModel.fromJson(Map<String, dynamic> json) => TipoRelacionLaboralModel(
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
    TipoRelacionLaboralEntity toEntity() => TipoRelacionLaboralEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory TipoRelacionLaboralModel.fromEntity(TipoRelacionLaboralEntity entity) => TipoRelacionLaboralModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
