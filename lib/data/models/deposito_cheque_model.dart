import 'dart:convert';

import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';

DepositoChequeModel depositoChequeModelFromJson(String str) =>
    DepositoChequeModel.fromJson(json.decode(str));

String depositoChequeModelToJson(DepositoChequeModel data) =>
    json.encode(data.toJson());

class DepositoChequeModel {
  final int idDeposito;
  final String codCliente;
  final int codEmpresa;
  final int idBxC;
  final double importe;
  final String moneda;
  final int estado;
  final String fotoPath;
  final double aCuenta;
  final DateTime? fechaI;
  final String nroTransaccion;
  final String obs;
  final int audUsuario;
  final int codBanco;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String nombreBanco;
  final String nombreEmpresa;
  final String esPendiente;
  final String numeroDeDocumentos;
  final String fechasDeDepositos;
  final String numeroDeFacturas;
  final String totalMontos;
  final String estadoFiltro;

  DepositoChequeModel({
    required this.idDeposito,
    required this.codCliente,
    required this.codEmpresa,
    required this.idBxC,
    required this.importe,
    required this.moneda,
    required this.estado,
    required this.fotoPath,
    required this.aCuenta,
    this.fechaI,
    required this.nroTransaccion,
    required this.obs,
    required this.audUsuario,
    required this.codBanco,
    required this.fechaInicio,
    required this.fechaFin,
    required this.nombreBanco,
    required this.nombreEmpresa,
    required this.esPendiente,
    required this.numeroDeDocumentos,
    required this.fechasDeDepositos,
    required this.numeroDeFacturas,
    required this.totalMontos,
    required this.estadoFiltro,
  });

  factory DepositoChequeModel.fromJson(Map<String, dynamic> json) =>
      DepositoChequeModel(
        idDeposito: json["idDeposito"],
        codCliente: json["codCliente"],
        codEmpresa: json["codEmpresa"],
        idBxC: json["idBxC"],
        importe: json["importe"]?.toDouble(),
        moneda: json["moneda"],
        estado: json["estado"],
        fotoPath: json["fotoPath"],
        aCuenta: json["aCuenta"]?.toDouble(),
        fechaI: json["fechaI"] != null ? DateTime.parse(json["fechaI"]) : null,
        nroTransaccion: json["nroTransaccion"],
        obs: json["obs"],
        audUsuario: json["audUsuario"],
        codBanco: json["codBanco"],
        fechaInicio: DateTime.parse(json["fechaInicio"]),
        fechaFin: DateTime.parse(json["fechaFin"]),
        nombreBanco: json["nombreBanco"],
        nombreEmpresa: json["nombreEmpresa"],
        esPendiente: json["esPendiente"],
        numeroDeDocumentos: json["numeroDeDocumentos"],
        fechasDeDepositos: json["fechasDeDepositos"],
        numeroDeFacturas: json["numeroDeFacturas"],
        totalMontos: json["totalMontos"],
        estadoFiltro: json["estadoFiltro"],
      );

  Map<String, dynamic> toJson() => {
    "idDeposito": idDeposito,
    "codCliente": codCliente,
    "codEmpresa": codEmpresa,
    "idBxC": idBxC,
    "importe": importe,
    "moneda": moneda,
    "estado": estado,
    "fotoPath": fotoPath,
    "aCuenta": aCuenta,
    if (fechaI != null) "fechaI": fechaI!.toIso8601String(),
    "nroTransaccion": nroTransaccion,
    "obs": obs,
    "audUsuario": audUsuario,
    "codBanco": codBanco,
    "fechaInicio": fechaInicio.toIso8601String(),
    "fechaFin": fechaFin.toIso8601String(),
    "nombreBanco": nombreBanco,
    "nombreEmpresa": nombreEmpresa,
    "esPendiente": esPendiente,
    "numeroDeDocumentos": numeroDeDocumentos,
    "fechasDeDepositos": fechasDeDepositos,
    "numeroDeFacturas": numeroDeFacturas,
    "totalMontos": totalMontos,
    "estadoFiltro": estadoFiltro,
  };

  // Método para convertir de Model a Entity
  DepositoChequeEntity toEntity() => DepositoChequeEntity(
    idDeposito: idDeposito,
    codCliente: codCliente,
    codEmpresa: codEmpresa,
    idBxC: idBxC,
    importe: importe,
    moneda: moneda,
    estado: estado,
    fotoPath: fotoPath,
    aCuenta: aCuenta,
    fechaI: fechaI,
    nroTransaccion: nroTransaccion,
    obs: obs,
    audUsuario: audUsuario,
    codBanco: codBanco,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    nombreBanco: nombreBanco,
    nombreEmpresa: nombreEmpresa,
    esPendiente: esPendiente,
    numeroDeDocumentos: numeroDeDocumentos,
    fechasDeDepositos: fechasDeDepositos,
    numeroDeFacturas: numeroDeFacturas,
    totalMontos: totalMontos,
    estadoFiltro: estadoFiltro,
  );

  // Método factory para convertir de Entity a Model
  factory DepositoChequeModel.fromEntity(DepositoChequeEntity entity) =>
      DepositoChequeModel(
        idDeposito: entity.idDeposito,
        codCliente: entity.codCliente,
        codEmpresa: entity.codEmpresa,
        idBxC: entity.idBxC,
        importe: entity.importe,
        moneda: entity.moneda,
        estado: entity.estado,
        fotoPath: entity.fotoPath,
        aCuenta: entity.aCuenta,
        fechaI: entity.fechaI,
        nroTransaccion: entity.nroTransaccion,
        obs: entity.obs,
        audUsuario: entity.audUsuario,
        codBanco: entity.codBanco,
        fechaInicio: entity.fechaInicio,
        fechaFin: entity.fechaFin,
        nombreBanco: entity.nombreBanco,
        nombreEmpresa: entity.nombreEmpresa,
        esPendiente: entity.esPendiente,
        numeroDeDocumentos: entity.numeroDeDocumentos,
        fechasDeDepositos: entity.fechasDeDepositos,
        numeroDeFacturas: entity.numeroDeFacturas,
        totalMontos: entity.totalMontos,
        estadoFiltro: entity.estadoFiltro,
      );
}
