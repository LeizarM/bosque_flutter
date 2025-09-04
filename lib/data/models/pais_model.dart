// To parse this JSON data, do
//
//     final paisModel = paisModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/pais_entity.dart';

List<PaisModel> paisModelFromJson(String str) => List<PaisModel>.from(json.decode(str).map((x) => PaisModel.fromJson(x)));

String paisModelToJson(List<PaisModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PaisModel {
    final int codPais;
    final String pais;
    final int audUsuario;

    PaisModel({
        required this.codPais,
        required this.pais,
        required this.audUsuario,
    });

    factory PaisModel.fromJson(Map<String, dynamic> json) => PaisModel(
        codPais: json["codPais"]?? 0,
        pais: json["pais"]?? '',
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codPais": codPais,
        "pais": pais,
        "audUsuario": audUsuario,
    };

    PaisEntity toEntity() => PaisEntity(
        codPais: codPais,
        pais: pais,
        audUsuario: audUsuario,
    );
    factory PaisModel.fromEntity(PaisEntity entity) => PaisModel(
        codPais: entity.codPais,
        pais: entity.pais,
        audUsuario: entity.audUsuario,
    );
}
