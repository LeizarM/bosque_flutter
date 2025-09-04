// To parse this JSON data, do
//
//     final telefonoModel = telefonoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/telefono_entity.dart';

List<TelefonoModel> telefonoModelFromJson(String str) => List<TelefonoModel>.from(json.decode(str).map((x) => TelefonoModel.fromJson(x)));

String telefonoModelToJson(List<TelefonoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TelefonoModel {
    final int codTelefono;
    final int codPersona;
    final int codTipoTel;
    final String telefono;
    final String tipo;
    final int audUsuario;

    TelefonoModel({
        required this.codTelefono,
        required this.codPersona,
        required this.codTipoTel,
        required this.telefono,
        required this.tipo,
        required this.audUsuario,
    });

    factory TelefonoModel.fromJson(Map<String, dynamic> json) => TelefonoModel(
        codTelefono: json["codTelefono"]?? 0,
        codPersona: json["codPersona"]?? 0,
        codTipoTel: json["codTipoTel"]?? 0,
        telefono: json["telefono"]??'',
        tipo: json["tipo"]??'',
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codTelefono": codTelefono,
        "codPersona": codPersona,
        "codTipoTel": codTipoTel,
        "telefono": telefono,
        "tipo": tipo,
        "audUsuario": audUsuario,
    };
    TelefonoEntity toEntity() => TelefonoEntity(
        codTelefono: codTelefono,
        codPersona: codPersona,
        codTipoTel: codTipoTel,
        telefono: telefono,
        tipo: tipo,
        audUsuario: audUsuario,
    ); 
    factory TelefonoModel.fromEntity(TelefonoEntity entity) => TelefonoModel(
        codTelefono: entity.codTelefono,
        codPersona: entity.codPersona,
        codTipoTel: entity.codTipoTel,
        telefono: entity.telefono,
        tipo: entity.tipo?? '',
        audUsuario: entity.audUsuario,
    );
}
