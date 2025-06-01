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
  final String fechaSolicitud; // Cambiar de DateTime a String
  final String motivo;
  final String solicitante;
  final String cargo;
  final String coche;
  final String estadoDisponibilidad;
  final int requiereChofer;
  final String estadoLateralesEntregaAux;
  final String estadoInteriorEntregaAux;
  final String estadoDelanteraEntregaAux;
  final String estadoTraseraEntregaAux;
  final String estadoCapoteEntregaAux;
  final String estadoLateralRecepcionAux;
  final String estadoInteriorRecepcionAux;
  final String estadoDelanteraRecepcionAux;
  final String estadoTraseraRecepcionAux;
  final String estadoCapoteRecepcionAux;

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
    required this.fechaSolicitud,
    required this.motivo,
    required this.solicitante,
    required this.cargo,
    required this.coche,
    required this.estadoDisponibilidad,
    required this.requiereChofer,
    required this.estadoLateralesEntregaAux,
    required this.estadoInteriorEntregaAux,
    required this.estadoDelanteraEntregaAux,
    required this.estadoTraseraEntregaAux,
    required this.estadoCapoteEntregaAux,
    required this.estadoLateralRecepcionAux,
    required this.estadoInteriorRecepcionAux,
    required this.estadoDelanteraRecepcionAux,
    required this.estadoTraseraRecepcionAux,
    required this.estadoCapoteRecepcionAux,
  });

  factory PrestamoChoferModel.fromJson(Map<String, dynamic> json) =>
      PrestamoChoferModel(
        idPrestamo: json["idPrestamo"] ?? 0,
        idCoche: json["idCoche"] ?? 0,
        idSolicitud: json["idSolicitud"] ?? 0,
        codSucursal: json["codSucursal"] ?? 0,
        fechaEntrega: json["fechaEntrega"] != null && json["fechaEntrega"] != '' 
            ? DateTime.tryParse(json["fechaEntrega"]) ?? DateTime(2000) 
            : DateTime(2000),
        codEmpChoferSolicitado: json["codEmpChoferSolicitado"] ?? 0,
        codEmpEntregadoPor: json["codEmpEntregadoPor"] ?? 0,
        kilometrajeEntrega: json["kilometrajeEntrega"]?.toDouble() ?? 0.0,
        kilometrajeRecepcion: json["kilometrajeRecepcion"]?.toDouble() ?? 0.0,
        nivelCombustibleEntrega: json["nivelCombustibleEntrega"] ?? 0, 
        nivelCombustibleRecepcion: json["nivelCombustibleRecepcion"] ?? 0,
        estadoLateralesEntrega: json["estadoLateralesEntrega"] ?? 0,
        estadoInteriorEntrega: json["estadoInteriorEntrega"] ?? 0,
        estadoDelanteraEntrega: json["estadoDelanteraEntrega"] ?? 0,
        estadoTraseraEntrega: json["estadoTraseraEntrega"] ?? 0,
        estadoCapoteEntrega: json["estadoCapoteEntrega"] ?? 0,
        estadoLateralRecepcion: json["estadoLateralRecepcion"] ?? 0,
        estadoInteriorRecepcion: json["estadoInteriorRecepcion"] ?? 0,
        estadoDelanteraRecepcion: json["estadoDelanteraRecepcion"] ?? 0,
        estadoTraseraRecepcion: json["estadoTraseraRecepcion"] ?? 0,
        estadoCapoteRecepcion: json["estadoCapoteRecepcion"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
        fechaSolicitud: json["fechaSolicitud"]?.toString() ?? '',
        motivo: json["motivo"] ?? '',
        solicitante: json["solicitante"] ?? '',
        cargo: json["cargo"] ?? '',
        coche: json["coche"] ?? '',
        estadoDisponibilidad: json["estadoDisponibilidad"] ?? '',
        requiereChofer: json["requiereChofer"] ?? 0,
        estadoLateralesEntregaAux: json["estadoLateralesEntregaAux"] ?? '',
        estadoInteriorEntregaAux: json["estadoInteriorEntregaAux"] ?? '',
        estadoDelanteraEntregaAux: json["estadoDelanteraEntregaAux"] ?? '',
        estadoTraseraEntregaAux: json["estadoTraseraEntregaAux"] ?? '',
        estadoCapoteEntregaAux: json["estadoCapoteEntregaAux"] ?? '',
        estadoLateralRecepcionAux: json["estadoLateralRecepcionAux"] ?? '',
        estadoInteriorRecepcionAux: json["estadoInteriorRecepcionAux"] ?? '',
        estadoDelanteraRecepcionAux: json["estadoDelanteraRecepcionAux"] ?? '',
        estadoTraseraRecepcionAux: json["estadoTraseraRecepcionAux"] ?? '',
        estadoCapoteRecepcionAux: json["estadoCapoteRecepcionAux"] ?? '',
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
    "fechaSolicitud": fechaSolicitud,
    "motivo": motivo,
    "solicitante": solicitante,
    "cargo": cargo,
    "coche": coche,
    "estadoDisponibilidad": estadoDisponibilidad,
    "requiereChofer": requiereChofer,
    "estadoLateralesEntregaAux": estadoLateralesEntregaAux,
    "estadoInteriorEntregaAux": estadoInteriorEntregaAux,
    "estadoDelanteraEntregaAux": estadoDelanteraEntregaAux,
    "estadoTraseraEntregaAux": estadoTraseraEntregaAux,
    "estadoCapoteEntregaAux": estadoCapoteEntregaAux,
    "estadoLateralRecepcionAux": estadoLateralRecepcionAux,
    "estadoInteriorRecepcionAux": estadoInteriorRecepcionAux,
    "estadoDelanteraRecepcionAux": estadoDelanteraRecepcionAux,
    "estadoTraseraRecepcionAux": estadoTraseraRecepcionAux,
    "estadoCapoteRecepcionAux": estadoCapoteRecepcionAux,
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
    fechaSolicitud: fechaSolicitud,
    motivo: motivo,
    solicitante: solicitante,
    cargo: cargo,
    coche: coche,
    estadoDisponibilidad: estadoDisponibilidad,
    requiereChofer: requiereChofer,
    estadoLateralesEntregaAux: estadoLateralesEntregaAux,
    estadoInteriorEntregaAux: estadoInteriorEntregaAux,
    estadoDelanteraEntregaAux: estadoDelanteraEntregaAux,
    estadoTraseraEntregaAux: estadoTraseraEntregaAux,
    estadoCapoteEntregaAux: estadoCapoteEntregaAux,
    estadoLateralRecepcionAux: estadoLateralRecepcionAux,
    estadoInteriorRecepcionAux: estadoInteriorRecepcionAux,
    estadoDelanteraRecepcionAux: estadoDelanteraRecepcionAux,
    estadoTraseraRecepcionAux: estadoTraseraRecepcionAux,
    estadoCapoteRecepcionAux: estadoCapoteRecepcionAux,
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
        fechaSolicitud: entity.fechaSolicitud,
        motivo: entity.motivo,
        solicitante: entity.solicitante,
        cargo: entity.cargo,
        coche: entity.coche,
        estadoDisponibilidad: entity.estadoDisponibilidad,
        requiereChofer: entity.requiereChofer,
        estadoLateralesEntregaAux: entity.estadoLateralesEntregaAux,
        estadoInteriorEntregaAux: entity.estadoInteriorEntregaAux,
        estadoDelanteraEntregaAux: entity.estadoDelanteraEntregaAux,
        estadoTraseraEntregaAux: entity.estadoTraseraEntregaAux,
        estadoCapoteEntregaAux: entity.estadoCapoteEntregaAux,
        estadoLateralRecepcionAux: entity.estadoLateralRecepcionAux,
        estadoInteriorRecepcionAux: entity.estadoInteriorRecepcionAux,
        estadoDelanteraRecepcionAux: entity.estadoDelanteraRecepcionAux,
        estadoTraseraRecepcionAux: entity.estadoTraseraRecepcionAux,
        estadoCapoteRecepcionAux: entity.estadoCapoteRecepcionAux,
      );
}
