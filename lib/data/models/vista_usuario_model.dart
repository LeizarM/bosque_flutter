import 'dart:convert';

import 'package:bosque_flutter/domain/entities/vista_usuario_entity.dart';

VistaUsuarioModel vistaUsuarioModelFromJson(String str) =>
    VistaUsuarioModel.fromJson(json.decode(str));

String vistaUsuarioModelToJson(VistaUsuarioModel data) =>
    json.encode(data.toJson());

class VistaUsuarioModel {
  int codUsuario;
  int codVista;
  int nivelAcceso;
  int autorizador;
  int audUsuarioI;

  VistaUsuarioModel({
    required this.codUsuario,
    required this.codVista,
    required this.nivelAcceso,
    required this.autorizador,
    required this.audUsuarioI,
  });

  factory VistaUsuarioModel.fromJson(Map<String, dynamic> json) =>
      VistaUsuarioModel(
        codUsuario: json["codUsuario"] ?? 0,
        codVista: json["codVista"] ?? 0,
        nivelAcceso: json["nivelAcceso"] ?? 0,
        autorizador: json["autorizador"] ?? 0,
        audUsuarioI: json["audUsuarioI"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "codUsuario": codUsuario,
    "codVista": codVista,
    "nivelAcceso": nivelAcceso,
    "autorizador": autorizador,
    "audUsuarioI": audUsuarioI,
  };

  // Método para convertir de Model a Entity
  VistaUsuarioEntity toEntity() => VistaUsuarioEntity(
    codUsuario: codUsuario,
    codVista: codVista,
    nivelAcceso: nivelAcceso,
    autorizador: autorizador,
    audUsuarioI: audUsuarioI,
  );

  // Método factory para convertir de Entity a Model
  factory VistaUsuarioModel.fromEntity(VistaUsuarioEntity entity) =>
      VistaUsuarioModel(
        codUsuario: entity.codUsuario,
        codVista: entity.codVista,
        nivelAcceso: entity.nivelAcceso,
        autorizador: entity.autorizador,
        audUsuarioI: entity.audUsuarioI,
      );
}
