// To parse this JSON data, do
//
//     final ciExpedidoModel = ciExpedidoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/ciExpedido_entity.dart';


List<CiExpedidoModel> ciExpedidoModelFromJson(String str) => List<CiExpedidoModel>.from(json.decode(str).map((x) => CiExpedidoModel.fromJson(x)));

String ciExpedidoModelToJson(List<CiExpedidoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CiExpedidoModel {
    final String codTipos;
    final String nombre;
    final int codGrupo;
    final dynamic listTipos;

    CiExpedidoModel({
        required this.codTipos,
        required this.nombre,
        required this.codGrupo,
        required this.listTipos,
    });

    factory CiExpedidoModel.fromJson(Map<String, dynamic> json) => CiExpedidoModel(
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
    CiExpedidoEntity toEntity()=> CiExpedidoEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
        listTipos: listTipos,
    );
    factory CiExpedidoModel.fromEntity(CiExpedidoEntity entity) => CiExpedidoModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
        listTipos: entity.listTipos,
    );
}
