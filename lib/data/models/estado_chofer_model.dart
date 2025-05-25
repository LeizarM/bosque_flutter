// To parse this JSON data, do
//
//     final estadoChoferModel = estadoChoferModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/estado_chofer_entity.dart';

EstadoChoferModel estadoChoferModelFromJson(String str) =>
    EstadoChoferModel.fromJson(json.decode(str));

String estadoChoferModelToJson(EstadoChoferModel data) =>
    json.encode(data.toJson());

class EstadoChoferModel {
  final int idEst;
  final String estado;
  final int audUsuario;

  EstadoChoferModel({
    required this.idEst,
    required this.estado,
    required this.audUsuario,
  });

  factory EstadoChoferModel.fromJson(Map<String, dynamic> json) =>
      EstadoChoferModel(
        idEst: json["idEst"],
        estado: json["estado"],
        audUsuario: json["audUsuario"],
      );

  Map<String, dynamic> toJson() => {
    "idEst": idEst,
    "estado": estado,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  EstadoChoferEntity toEntity() =>
      EstadoChoferEntity(idEst: idEst, estado: estado, audUsuario: audUsuario);

  // Método factory para convertir de Entity a Model
  factory EstadoChoferModel.fromEntity(EstadoChoferEntity entity) =>
      EstadoChoferModel(
        idEst: entity.idEst,
        estado: entity.estado,
        audUsuario: entity.audUsuario,
      );
}
