import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_solicitud_entity.dart';

TipoSolicitudModel tipoSolicitudModelFromJson(String str) =>
    TipoSolicitudModel.fromJson(json.decode(str));

String tipoSolicitudModelToJson(TipoSolicitudModel data) =>
    json.encode(data.toJson());

class TipoSolicitudModel {
  final int idES;
  final String descripcion;
  final int estado;
  final int audUsuario;

  TipoSolicitudModel({
    required this.idES,
    required this.descripcion,
    required this.estado,
    required this.audUsuario,
  });

  factory TipoSolicitudModel.fromJson(Map<String, dynamic> json) =>
      TipoSolicitudModel(
        idES: json["idES"] ?? 0,
        descripcion: json["descripcion"] ?? '',
        estado: json["estado"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idES": idES,
    "descripcion": descripcion,
    "estado": estado,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  TipoSolicitudEntity toEntity() => TipoSolicitudEntity(
    idES: idES,
    descripcion: descripcion,
    estado: estado,
    audUsuario: audUsuario,
  );

  // Método factory para convertir de Entity a Model
  factory TipoSolicitudModel.fromEntity(TipoSolicitudEntity entity) =>
      TipoSolicitudModel(
        idES: entity.idES,
        descripcion: entity.descripcion,
        estado: entity.estado,
        audUsuario: entity.audUsuario,
      );
}
