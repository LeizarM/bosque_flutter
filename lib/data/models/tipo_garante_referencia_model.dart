// To parse this JSON data, do
//
//     final tipoGaranteReferenciaModel = tipoGaranteReferenciaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_garante_referencia_entity.dart';

List<TipoGaranteReferenciaModel> tipoGaranteReferenciaModelFromJson(String str) => List<TipoGaranteReferenciaModel>.from(json.decode(str).map((x) => TipoGaranteReferenciaModel.fromJson(x)));

String tipoGaranteReferenciaModelToJson(List<TipoGaranteReferenciaModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoGaranteReferenciaModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    TipoGaranteReferenciaModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoGaranteReferenciaModel.fromJson(Map<String, dynamic> json) => TipoGaranteReferenciaModel(
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
    TipoGaranteReferenciaEntity toEntity() => TipoGaranteReferenciaEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory TipoGaranteReferenciaModel.fromEntity(TipoGaranteReferenciaEntity entity) => TipoGaranteReferenciaModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
