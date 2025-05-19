// To parse this JSON data, do
//
//     final usuarioBtnModel = usuarioBtnModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';

UsuarioBtnModel usuarioBtnModelFromJson(String str) =>
    UsuarioBtnModel.fromJson(json.decode(str));

String usuarioBtnModelToJson(UsuarioBtnModel data) =>
    json.encode(data.toJson());

class UsuarioBtnModel {
  final int codUsuario;
  final int codBtn;
  final int nivelAcceso;
  final int audUsuario;
  final String boton;
  final int permiso;
  final int pertenVist;

  UsuarioBtnModel({
    required this.codUsuario,
    required this.codBtn,
    required this.nivelAcceso,
    required this.audUsuario,
    required this.boton,
    required this.permiso,
    required this.pertenVist,
  });

  factory UsuarioBtnModel.fromJson(Map<String, dynamic> json) =>
      UsuarioBtnModel(
        codUsuario: json["codUsuario"],
        codBtn: json["codBtn"],
        nivelAcceso: json["nivelAcceso"],
        audUsuario: json["audUsuario"],
        boton: json["boton"],
        permiso: json["permiso"],
        pertenVist: json["pertenVist"],
      );

  Map<String, dynamic> toJson() => {
    "codUsuario": codUsuario,
    "codBtn": codBtn,
    "nivelAcceso": nivelAcceso,
    "audUsuario": audUsuario,
    "boton": boton,
    "permiso": permiso,
    "pertenVist": pertenVist,
  };

  // Método para convertir de Model a Entity
  UsuarioBtnEntity toEntity() => UsuarioBtnEntity(
    codUsuario: codUsuario,
    codBtn: codBtn,
    nivelAcceso: nivelAcceso,
    audUsuario: audUsuario,
    boton: boton,
    permiso: permiso,
    pertenVist: pertenVist,
  );

  // Método factory para convertir de Entity a Model
  factory UsuarioBtnModel.fromEntity(UsuarioBtnEntity entity) =>
      UsuarioBtnModel(
        codUsuario: entity.codUsuario,
        codBtn: entity.codBtn,
        nivelAcceso: entity.nivelAcceso,
        audUsuario: entity.audUsuario,
        boton: entity.boton,
        permiso: entity.permiso,
        pertenVist: entity.pertenVist,
      );
}
