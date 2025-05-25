// To parse this JSON data, do
//
//     final prestamoEstadoModel = prestamoEstadoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/prestamo_estado_entity.dart';

PrestamoEstadoModel prestamoEstadoModelFromJson(String str) =>
    PrestamoEstadoModel.fromJson(json.decode(str));

String prestamoEstadoModelToJson(PrestamoEstadoModel data) =>
    json.encode(data.toJson());

class PrestamoEstadoModel {
  final int idPE;
  final int idPrestamo;
  final int idEst;
  final String momento;
  final int audUsuario;

  PrestamoEstadoModel({
    required this.idPE,
    required this.idPrestamo,
    required this.idEst,
    required this.momento,
    required this.audUsuario,
  });

  factory PrestamoEstadoModel.fromJson(Map<String, dynamic> json) =>
      PrestamoEstadoModel(
        idPE: json["idPE"],
        idPrestamo: json["idPrestamo"],
        idEst: json["idEst"],
        momento: json["momento"],
        audUsuario: json["audUsuario"],
      );

  Map<String, dynamic> toJson() => {
    "idPE": idPE,
    "idPrestamo": idPrestamo,
    "idEst": idEst,
    "momento": momento,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  PrestamoEstadoEntity toEntity() => PrestamoEstadoEntity(
    idPE: idPE,
    idPrestamo: idPrestamo,
    idEst: idEst,
    momento: momento,
    audUsuario: audUsuario,
  );

  // Método factory para convertir de Entity a Model
  factory PrestamoEstadoModel.fromEntity(PrestamoEstadoEntity entity) =>
      PrestamoEstadoModel(
        idPE: entity.idPE,
        idPrestamo: entity.idPrestamo,
        idEst: entity.idEst,
        momento: entity.momento,
        audUsuario: entity.audUsuario,
      );
}
