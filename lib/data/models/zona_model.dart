// To parse this JSON data, do
//
//     final zonaModel = zonaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/zona_entity.dart';

List<ZonaModel> zonaModelFromJson(String str) => List<ZonaModel>.from(json.decode(str).map((x) => ZonaModel.fromJson(x)));

String zonaModelToJson(List<ZonaModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ZonaModel {
    final int codZona;
    final int codCiudad;
    final String zona;
    final int audUsuario;

    ZonaModel({
        required this.codZona,
        required this.codCiudad,
        required this.zona,
        required this.audUsuario,
    });

    factory ZonaModel.fromJson(Map<String, dynamic> json) => ZonaModel(
        codZona: json["codZona"]?? 0,
        codCiudad: json["codCiudad"]?? 0,
        zona: json["zona"]??'',
        audUsuario: json["audUsuario"]??0,
    );

    Map<String, dynamic> toJson() => {
        "codZona": codZona,
        "codCiudad": codCiudad,
        "zona": zona,
        "audUsuario": audUsuario,
    };
    ZonaEntity toEntity() => ZonaEntity(
        codZona: codZona,
        codCiudad: codCiudad,
        zona: zona,
        audUsuario: audUsuario,
    );
    factory ZonaModel.fromEntity(ZonaEntity entity) => ZonaModel(
        codZona: entity.codZona,
        codCiudad: entity.codCiudad,
        zona: entity.zona,
        audUsuario: entity.audUsuario,
    );

  
}
