// To parse this JSON data, do
//
//     final prestamoChoferModel = prestamoChoferModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/prestamo_chofer_entity.dart';

PrestamoChoferModel prestamoChoferModelFromJson(String str) =>
    PrestamoChoferModel.fromJson(json.decode(str));

String prestamoChoferModelToJson(PrestamoChoferModel data) =>
    json.encode(data.toJson());

class PrestamoChoferModel {
  final int idPrestamo;
  final int idCoche;
  final int idSolicitud;
  final int codSucursal;
  final DateTime fechaEntrega;
  final int codEmpChoferSolicitado;
  final int codEmpEntregadoPor;
  final double kilometrajeEntrega;
  final double kilometrajeRecepcion;
  final int nivelCombustibleEntrega;
  final int nivelCombustibleRecepcion;
  final int estadoLateralesEntrega;
  final int estadoInteriorEntrega;
  final int estadoDelanteraEntrega;
  final int estadoTraseraEntrega;
  final int estadoCapoteEntrega;
  final int estadoLateralRecepcion;
  final int estadoInteriorRecepcion;
  final int estadoDelanteraRecepcion;
  final int estadoTraseraRecepcion;
  final int estadoCapoteRecepcion;
  final int audUsuario;
  final int requiereChofer;

  PrestamoChoferModel({
    required this.idPrestamo,
    required this.idCoche,
    required this.idSolicitud,
    required this.codSucursal,
    required this.fechaEntrega,
    required this.codEmpChoferSolicitado,
    required this.codEmpEntregadoPor,
    required this.kilometrajeEntrega,
    required this.kilometrajeRecepcion,
    required this.nivelCombustibleEntrega,
    required this.nivelCombustibleRecepcion,
    required this.estadoLateralesEntrega,
    required this.estadoInteriorEntrega,
    required this.estadoDelanteraEntrega,
    required this.estadoTraseraEntrega,
    required this.estadoCapoteEntrega,
    required this.estadoLateralRecepcion,
    required this.estadoInteriorRecepcion,
    required this.estadoDelanteraRecepcion,
    required this.estadoTraseraRecepcion,
    required this.estadoCapoteRecepcion,
    required this.audUsuario,
    required this.requiereChofer,
  });

  factory PrestamoChoferModel.fromJson(Map<String, dynamic> json) =>
      PrestamoChoferModel(
        idPrestamo: json["idPrestamo"],
        idCoche: json["idCoche"],
        idSolicitud: json["idSolicitud"],
        codSucursal: json["codSucursal"],
        fechaEntrega: DateTime.parse(json["fechaEntrega"]),
        codEmpChoferSolicitado: json["codEmpChoferSolicitado"],
        codEmpEntregadoPor: json["codEmpEntregadoPor"],
        kilometrajeEntrega: json["kilometrajeEntrega"]?.toDouble(),
        kilometrajeRecepcion: json["kilometrajeRecepcion"]?.toDouble(),
        nivelCombustibleEntrega: json["nivelCombustibleEntrega"],
        nivelCombustibleRecepcion: json["nivelCombustibleRecepcion"],
        estadoLateralesEntrega: json["estadoLateralesEntrega"],
        estadoInteriorEntrega: json["estadoInteriorEntrega"],
        estadoDelanteraEntrega: json["estadoDelanteraEntrega"],
        estadoTraseraEntrega: json["estadoTraseraEntrega"],
        estadoCapoteEntrega: json["estadoCapoteEntrega"],
        estadoLateralRecepcion: json["estadoLateralRecepcion"],
        estadoInteriorRecepcion: json["estadoInteriorRecepcion"],
        estadoDelanteraRecepcion: json["estadoDelanteraRecepcion"],
        estadoTraseraRecepcion: json["estadoTraseraRecepcion"],
        estadoCapoteRecepcion: json["estadoCapoteRecepcion"],
        audUsuario: json["audUsuario"],
        requiereChofer: json["requiereChofer"],
      );

  Map<String, dynamic> toJson() => {
    "idPrestamo": idPrestamo,
    "idCoche": idCoche,
    "idSolicitud": idSolicitud,
    "codSucursal": codSucursal,
    "fechaEntrega": fechaEntrega.toIso8601String(),
    "codEmpChoferSolicitado": codEmpChoferSolicitado,
    "codEmpEntregadoPor": codEmpEntregadoPor,
    "kilometrajeEntrega": kilometrajeEntrega,
    "kilometrajeRecepcion": kilometrajeRecepcion,
    "nivelCombustibleEntrega": nivelCombustibleEntrega,
    "nivelCombustibleRecepcion": nivelCombustibleRecepcion,
    "estadoLateralesEntrega": estadoLateralesEntrega,
    "estadoInteriorEntrega": estadoInteriorEntrega,
    "estadoDelanteraEntrega": estadoDelanteraEntrega,
    "estadoTraseraEntrega": estadoTraseraEntrega,
    "estadoCapoteEntrega": estadoCapoteEntrega,
    "estadoLateralRecepcion": estadoLateralRecepcion,
    "estadoInteriorRecepcion": estadoInteriorRecepcion,
    "estadoDelanteraRecepcion": estadoDelanteraRecepcion,
    "estadoTraseraRecepcion": estadoTraseraRecepcion,
    "estadoCapoteRecepcion": estadoCapoteRecepcion,
    "audUsuario": audUsuario,
    "requiereChofer": requiereChofer,
  };

  // Método para convertir de Model a Entity
  PrestamoChoferEntity toEntity() => PrestamoChoferEntity(
    idPrestamo: idPrestamo,
    idCoche: idCoche,
    idSolicitud: idSolicitud,
    codSucursal: codSucursal,
    fechaEntrega: fechaEntrega,
    codEmpChoferSolicitado: codEmpChoferSolicitado,
    codEmpEntregadoPor: codEmpEntregadoPor,
    kilometrajeEntrega: kilometrajeEntrega,
    kilometrajeRecepcion: kilometrajeRecepcion,
    nivelCombustibleEntrega: nivelCombustibleEntrega,
    nivelCombustibleRecepcion: nivelCombustibleRecepcion,
    estadoLateralesEntrega: estadoLateralesEntrega,
    estadoInteriorEntrega: estadoInteriorEntrega,
    estadoDelanteraEntrega: estadoDelanteraEntrega,
    estadoTraseraEntrega: estadoTraseraEntrega,
    estadoCapoteEntrega: estadoCapoteEntrega,
    estadoLateralRecepcion: estadoLateralRecepcion,
    estadoInteriorRecepcion: estadoInteriorRecepcion,
    estadoDelanteraRecepcion: estadoDelanteraRecepcion,
    estadoTraseraRecepcion: estadoTraseraRecepcion,
    estadoCapoteRecepcion: estadoCapoteRecepcion,
    audUsuario: audUsuario,
    requiereChofer: requiereChofer,
  );

  // Método factory para convertir de Entity a Model
  factory PrestamoChoferModel.fromEntity(PrestamoChoferEntity entity) =>
      PrestamoChoferModel(
        idPrestamo: entity.idPrestamo,
        idCoche: entity.idCoche,
        idSolicitud: entity.idSolicitud,
        codSucursal: entity.codSucursal,
        fechaEntrega: entity.fechaEntrega,
        codEmpChoferSolicitado: entity.codEmpChoferSolicitado,
        codEmpEntregadoPor: entity.codEmpEntregadoPor,
        kilometrajeEntrega: entity.kilometrajeEntrega,
        kilometrajeRecepcion: entity.kilometrajeRecepcion,
        nivelCombustibleEntrega: entity.nivelCombustibleEntrega,
        nivelCombustibleRecepcion: entity.nivelCombustibleRecepcion,
        estadoLateralesEntrega: entity.estadoLateralesEntrega,
        estadoInteriorEntrega: entity.estadoInteriorEntrega,
        estadoDelanteraEntrega: entity.estadoDelanteraEntrega,
        estadoTraseraEntrega: entity.estadoTraseraEntrega,
        estadoCapoteEntrega: entity.estadoCapoteEntrega,
        estadoLateralRecepcion: entity.estadoLateralRecepcion,
        estadoInteriorRecepcion: entity.estadoInteriorRecepcion,
        estadoDelanteraRecepcion: entity.estadoDelanteraRecepcion,
        estadoTraseraRecepcion: entity.estadoTraseraRecepcion,
        estadoCapoteRecepcion: entity.estadoCapoteRecepcion,
        audUsuario: entity.audUsuario,
        requiereChofer: entity.requiereChofer,
      );
}
