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
  final int idES;
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
    required this.idES,
    required this.requiereChofer,
    required this.audUsuario,
    required this.fechaSolicitudCad,
    required this.estadoCad,
    required this.codSucursal,
    required this.coche,
  });

  factory SolicitudChoferModel.fromJson(Map<String, dynamic> json) =>
      SolicitudChoferModel(
        idSolicitud: json["idSolicitud"] ?? 0,
        fechaSolicitud: json["fechaSolicitud"] != null 
            ? DateTime.parse(json["fechaSolicitud"]) 
            : DateTime.now(),
        motivo: json["motivo"] ?? '',
        codEmpSoli: json["codEmpSoli"] ?? 0,
        cargo: json["cargo"] ?? '',
        estado: json["estado"] ?? 0,
        idCocheSol: json["idCocheSol"] ?? 0,
        idES: json["idES"] ?? 0,
        requiereChofer: json["requiereChofer"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
        fechaSolicitudCad: json["fechaSolicitudCad"] ?? '',
        estadoCad: json["estadoCad"] ?? '',
        codSucursal: json["codSucursal"] ?? 0,
        coche: json["coche"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "idSolicitud": idSolicitud,
    "fechaSolicitud": fechaSolicitud.toIso8601String(),
    "motivo": motivo,
    "codEmpSoli": codEmpSoli,
    "cargo": cargo,
    "estado": estado,
    "idCocheSol": idCocheSol,
    "idES": idES,
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
    idES: idES,
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
        idES: entity.idES,
        requiereChofer: entity.requiereChofer,
        audUsuario: entity.audUsuario,
        fechaSolicitudCad: entity.fechaSolicitudCad,
        estadoCad: entity.estadoCad,
        codSucursal: entity.codSucursal,
        coche: entity.coche,
      );
}
