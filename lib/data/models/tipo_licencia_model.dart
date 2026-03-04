// To parse this JSON data, do
//
//     final tipoLicenciaModel = tipoLicenciaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_licencia_entity.dart';

List<TipoLicenciaModel> tipoLicenciaModelFromJson(String str) => List<TipoLicenciaModel>.from(json.decode(str).map((x) => TipoLicenciaModel.fromJson(x)));

String tipoLicenciaModelToJson(List<TipoLicenciaModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoLicenciaModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    TipoLicenciaModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory TipoLicenciaModel.fromJson(Map<String, dynamic> json) => TipoLicenciaModel(
        codTipos: json["codTipos"]??0,
        nombre: json["nombre"]??'',
        codGrupo: json["codGrupo"]??0,
        listTipos: json["listTipos"]??'',
    );

    Map<String, dynamic> toJson() => {
        "codTipos": codTipos,
        "nombre": nombre,
        "codGrupo": codGrupo,
        "listTipos": listTipos,
    };
    //meotodo toEntity
    TipoLicenciaEntity toEntity () => TipoLicenciaEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    //metodo fromEntity
    factory TipoLicenciaModel.fromEntity (TipoLicenciaEntity entity) => TipoLicenciaModel(
        codTipos: entity.codTipos,
        nombre:  entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
