// To parse this JSON data, do
//
//     final bancoModel = bancoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/banco_entity.dart';

List<BancoModel> bancoModelFromJson(String str) => List<BancoModel>.from(json.decode(str).map((x) => BancoModel.fromJson(x)));

String bancoModelToJson(List<BancoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BancoModel {
    final int codBanco;
    final String nombre;
    final int audUsuario;
    final int fila;

    BancoModel({
        required this.codBanco,
        required this.nombre,
        required this.audUsuario,
        required this.fila,
    });

    factory BancoModel.fromJson(Map<String, dynamic> json) => BancoModel(
        codBanco: json["codBanco"]??0,
        nombre: json["nombre"]??'',
        audUsuario: json["audUsuario"]??0,
        fila: json["fila"]??0,
    );

    Map<String, dynamic> toJson() => {
        "codBanco": codBanco,
        "nombre": nombre,
        "audUsuario": audUsuario,
        "fila": fila,
    };
    BancoEntity toEntity() => BancoEntity(
        codBanco: codBanco,
        nombre: nombre,
        audUsuario: audUsuario,
        fila: fila,
    );
    factory BancoModel.fromEntity(BancoEntity entity) => BancoModel(
        codBanco: entity.codBanco,
        nombre: entity.nombre,
        audUsuario: entity.audUsuario,
        fila: entity.fila,
    );
}
