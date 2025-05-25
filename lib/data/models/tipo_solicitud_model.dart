import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tipo_solicitud_entity.dart';

TipoSolicitudModel tipoSolicitudModelFromJson(String str) =>
    TipoSolicitudModel.fromJson(json.decode(str));

String tipoSolicitudModelToJson(TipoSolicitudModel data) =>
    json.encode(data.toJson());

class TipoSolicitudModel {
  final int idEs;
  final String descripcion;
  final int estado;
  final int audUsuario;

  TipoSolicitudModel({
    required this.idEs,
    required this.descripcion,
    required this.estado,
    required this.audUsuario,
  });

  factory TipoSolicitudModel.fromJson(Map<String, dynamic> json) =>
      TipoSolicitudModel(
        idEs: json["idEs"],
        descripcion: json["descripcion"],
        estado: json["estado"],
        audUsuario: json["audUsuario"],
      );

  Map<String, dynamic> toJson() => {
    "idEs": idEs,
    "descripcion": descripcion,
    "estado": estado,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  TipoSolicitudEntity toEntity() => TipoSolicitudEntity(
    idEs: idEs,
    descripcion: descripcion,
    estado: estado,
    audUsuario: audUsuario,
  );

  // Método factory para convertir de Entity a Model
  factory TipoSolicitudModel.fromEntity(TipoSolicitudEntity entity) =>
      TipoSolicitudModel(
        idEs: entity.idEs,
        descripcion: entity.descripcion,
        estado: entity.estado,
        audUsuario: entity.audUsuario,
      );
}
