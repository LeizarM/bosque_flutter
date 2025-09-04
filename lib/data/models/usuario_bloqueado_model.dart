// To parse this JSON data, do
//
//     final usuarioBloqueadoModel = usuarioBloqueadoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/usuario_bloqueado_entity.dart';

UsuarioBloqueadoModel usuarioBloqueadoModelFromJson(String str) => UsuarioBloqueadoModel.fromJson(json.decode(str));

String usuarioBloqueadoModelToJson(UsuarioBloqueadoModel data) => json.encode(data.toJson());

class UsuarioBloqueadoModel {
    final int codUsuario;
    final DateTime fechaAdvertencia;
    final DateTime fechaLimite;
    final int bloqueado;
    final int audUsuario;

    UsuarioBloqueadoModel({
        required this.codUsuario,
        required this.fechaAdvertencia,
        required this.fechaLimite,
        required this.bloqueado,
        required this.audUsuario,
    });

    factory UsuarioBloqueadoModel.fromJson(Map<String, dynamic> json) => UsuarioBloqueadoModel(
        codUsuario: json["codUsuario"]??0,
        fechaAdvertencia:json["fechaAdvertencia"] != null ? DateTime.parse(json["fechaAdvertencia"]) : DateTime.now(),
        fechaLimite: json["fechaLimite"] != null ? DateTime.parse(json["fechaLimite"]) : DateTime.now(),
        bloqueado: json["bloqueado"]??0,
        audUsuario: json["audUsuario"]??0,
    );

    Map<String, dynamic> toJson() => {
        "codUsuario": codUsuario,
        "fechaAdvertencia": fechaAdvertencia.toIso8601String(),
        "fechaLimite": fechaLimite.toIso8601String(),
        "bloqueado": bloqueado,
        "audUsuario": audUsuario,
    };
    UsuarioBloqueadoEntity toEntity() => UsuarioBloqueadoEntity(
      codUsuario: codUsuario,
      fechaAdvertencia: fechaAdvertencia,
      fechaLimite: fechaLimite,
      bloqueado: bloqueado,
      audUsuario: audUsuario,
    );
    factory UsuarioBloqueadoModel.fromEntity(UsuarioBloqueadoEntity entity) => UsuarioBloqueadoModel(
      codUsuario: entity.codUsuario,
      fechaAdvertencia: entity.fechaAdvertencia,
      fechaLimite: entity.fechaLimite,
      bloqueado: entity.bloqueado,
      audUsuario: entity.audUsuario,
    );
}
