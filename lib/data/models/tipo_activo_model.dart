// To parse this JSON data, do
//
//     final tipoActivoModel = tipoActivoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_activo_entity.dart';

List<TipoActivoModel> tipoActivoModelFromJson(String str) => List<TipoActivoModel>.from(json.decode(str).map((x) => TipoActivoModel.fromJson(x)));

String tipoActivoModelToJson(List<TipoActivoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoActivoModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    TipoActivoModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoActivoModel.fromJson(Map<String, dynamic> json) => TipoActivoModel(
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
    TipoActivoEntity toEntity()=> TipoActivoEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory TipoActivoModel.fromEntity(TipoActivoEntity entity) => TipoActivoModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
    
}
