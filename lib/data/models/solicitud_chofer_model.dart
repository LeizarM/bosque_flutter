// To parse this JSON data, do
//
//     final solicitudChoferModel = solicitudChoferModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';

SolicitudChoferModel solicitudChoferModelFromJson(String str) =>
    SolicitudChoferModel.fromJson(json.decode(str));

String solicitudChoferModelToJson(SolicitudChoferModel data) =>
    json.encode(data.toJson());

class SolicitudChoferModel {
  final int idSolicitud;
  final DateTime fechaSolicitud;
  final String motivo;
  final int codEmpSoli;
  final String cargo;
  final int estado;
  final int idCocheSol;
  final int idEs;
  final int requiereChofer;
  final int audUsuario;
  final String fechaSolicitudCad;
  final String estadoCad;
  final int codSucursal;
  final String coche;

  SolicitudChoferModel({
    required this.idSolicitud,
    required this.fechaSolicitud,
    required this.motivo,
    required this.codEmpSoli,
    required this.cargo,
    required this.estado,
    required this.idCocheSol,
    required this.idEs,
    required this.requiereChofer,
    required this.audUsuario,
    required this.fechaSolicitudCad,
    required this.estadoCad,
    required this.codSucursal,
    required this.coche,
  });

  factory SolicitudChoferModel.fromJson(Map<String, dynamic> json) =>
      SolicitudChoferModel(
        idSolicitud: json["idSolicitud"],
        fechaSolicitud: DateTime.parse(json["fechaSolicitud"]),
        motivo: json["motivo"],
        codEmpSoli: json["codEmpSoli"],
        cargo: json["cargo"],
        estado: json["estado"],
        idCocheSol: json["idCocheSol"],
        idEs: json["idES"],
        requiereChofer: json["requiereChofer"],
        audUsuario: json["audUsuario"],
        fechaSolicitudCad: json["fechaSolicitudCad"],
        estadoCad: json["estadoCad"],
        codSucursal: json["codSucursal"],
        coche: json["coche"],
      );

  Map<String, dynamic> toJson() => {
    "idSolicitud": idSolicitud,
    "fechaSolicitud": fechaSolicitud.toIso8601String(),
    "motivo": motivo,
    "codEmpSoli": codEmpSoli,
    "cargo": cargo,
    "estado": estado,
    "idCocheSol": idCocheSol,
    "idES": idEs,
    "requiereChofer": requiereChofer,
    "audUsuario": audUsuario,
    "fechaSolicitudCad": fechaSolicitudCad,
    "estadoCad": estadoCad,
    "codSucursal": codSucursal,
    "coche": coche,
  };

  // Método para convertir de Model a Entity
  SolicitudChoferEntity toEntity() => SolicitudChoferEntity(
    idSolicitud: idSolicitud,
    fechaSolicitud: fechaSolicitud,
    motivo: motivo,
    codEmpSoli: codEmpSoli,
    cargo: cargo,
    estado: estado,
    idCocheSol: idCocheSol,
    idEs: idEs,
    requiereChofer: requiereChofer,
    audUsuario: audUsuario,
    fechaSolicitudCad: fechaSolicitudCad,
    estadoCad: estadoCad,
    codSucursal: codSucursal,
    coche: coche,
  );

  // Método factory para convertir de Entity a Model
  factory SolicitudChoferModel.fromEntity(SolicitudChoferEntity entity) =>
      SolicitudChoferModel(
        idSolicitud: entity.idSolicitud,
        fechaSolicitud: entity.fechaSolicitud,
        motivo: entity.motivo,
        codEmpSoli: entity.codEmpSoli,
        cargo: entity.cargo,
        estado: entity.estado,
        idCocheSol: entity.idCocheSol,
        idEs: entity.idEs,
        requiereChofer: entity.requiereChofer,
        audUsuario: entity.audUsuario,
        fechaSolicitudCad: entity.fechaSolicitudCad,
        estadoCad: entity.estadoCad,
        codSucursal: entity.codSucursal,
        coche: entity.coche,
      );
}
