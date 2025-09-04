// To parse this JSON data, do
//
//     final tipoTelefonoModel = tipoTelefonoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';

List<TipoTelefonoModel> tipoTelefonoModelFromJson(String str) => List<TipoTelefonoModel>.from(json.decode(str).map((x) => TipoTelefonoModel.fromJson(x)));

String tipoTelefonoModelToJson(List<TipoTelefonoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TipoTelefonoModel {
    final int codTipoTel;
    final String tipo;
    final int audUsuario;

    TipoTelefonoModel({
        required this.codTipoTel,
        required this.tipo,
        required this.audUsuario,
    });

    factory TipoTelefonoModel.fromJson(Map<String, dynamic> json) => TipoTelefonoModel(
        codTipoTel: json["codTipoTel"] ?? 0,
        tipo: json["tipo"] ?? '',
        audUsuario: json["audUsuario"] ?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codTipoTel": codTipoTel,
        "tipo": tipo,
        "audUsuario": audUsuario,
    };

    TipoTelefonoEntity toEntity() => TipoTelefonoEntity(
        codTipoTel: codTipoTel,
        tipo: tipo,
        audUsuario: audUsuario,
    );
    factory TipoTelefonoModel.fromEntity(TipoTelefonoEntity entity) => TipoTelefonoModel(
        codTipoTel: entity.codTipoTel,
        tipo: entity.tipo,
        audUsuario: entity.audUsuario,
    );
}
