// To parse this JSON data, do
//
//     final ciudadModel = ciudadModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';

List<CiudadModel> ciudadModelFromJson(String str) => List<CiudadModel>.from(json.decode(str).map((x) => CiudadModel.fromJson(x)));

String ciudadModelToJson(List<CiudadModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CiudadModel {
    final int codCiudad;
    final int codPais;
    final String ciudad;
    final int audUsuario;

    CiudadModel({
        required this.codCiudad,
        required this.codPais,
        required this.ciudad,
        required this.audUsuario,
    });

    factory CiudadModel.fromJson(Map<String, dynamic> json) => CiudadModel(
        codCiudad: json["codCiudad"]?? 0,
        codPais: json["codPais"]?? 0,
        ciudad: json["ciudad"]?? '',
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codCiudad": codCiudad,
        "codPais": codPais,
        "ciudad": ciudad,
        "audUsuario": audUsuario,
    };
    CiudadEntity toEntity()=> CiudadEntity(
        codCiudad: codCiudad,
        codPais: codPais,
        ciudad: ciudad,
        audUsuario: audUsuario,
    );
    factory CiudadModel.fromEntity(CiudadEntity entity) => CiudadModel(
        codCiudad: entity.codCiudad,
        codPais: entity.codPais,
        ciudad: entity.ciudad,
        audUsuario: entity.audUsuario,
    );
}
