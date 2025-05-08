// To parse this JSON data, do
//
//     final socioNegocioModel = socioNegocioModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';

SocioNegocioModel socioNegocioModelFromJson(String str) =>
    SocioNegocioModel.fromJson(json.decode(str));

String socioNegocioModelToJson(SocioNegocioModel data) =>
    json.encode(data.toJson());

class SocioNegocioModel {
  final String codCliente;
  final String datoCliente;
  final String razonSocial;
  final String nit;
  final int codCiudad;
  final String datoCiudad;
  final String esVigente;
  final int codEmpresa;
  final int audUsuario;
  final String nombreCompleto;

  SocioNegocioModel({
    required this.codCliente,
    required this.datoCliente,
    required this.razonSocial,
    required this.nit,
    required this.codCiudad,
    required this.datoCiudad,
    required this.esVigente,
    required this.codEmpresa,
    required this.audUsuario,
    required this.nombreCompleto,
  });

  factory SocioNegocioModel.fromJson(Map<String, dynamic> json) =>
      SocioNegocioModel(
        codCliente: json["codCliente"],
        datoCliente: json["datoCliente"] ?? "",
        razonSocial: json["razonSocial"],
        nit: json["nit"] ?? "",
        codCiudad: json["codCiudad"],
        datoCiudad: json["datoCiudad"] ?? "",
        esVigente: json["esVigente"] ?? "",
        codEmpresa: json["codEmpresa"],
        audUsuario: json["audUsuario"],
        nombreCompleto: json["nombreCompleto"],
      );

  Map<String, dynamic> toJson() => {
    "codCliente": codCliente,
    "datoCliente": datoCliente,
    "razonSocial": razonSocial,
    "nit": nit,
    "codCiudad": codCiudad,
    "datoCiudad": datoCiudad,
    "esVigente": esVigente,
    "codEmpresa": codEmpresa,
    "audUsuario": audUsuario,
    "nombreCompleto": nombreCompleto,
  };

  // Método para convertir de Model a Entity
  SocioNegocioEntity toEntity() => SocioNegocioEntity(
    codCliente: codCliente,
    datoCliente: datoCliente,
    razonSocial: razonSocial,
    nit: nit,
    codCiudad: codCiudad,
    datoCiudad: datoCiudad,
    esVigente: esVigente,
    codEmpresa: codEmpresa,
    audUsuario: audUsuario,
    nombreCompleto: nombreCompleto,
  );

  // Método factory para convertir de Entity a Model
  factory SocioNegocioModel.fromEntity(SocioNegocioEntity entity) =>
      SocioNegocioModel(
        codCliente: entity.codCliente,
        datoCliente: entity.datoCliente,
        razonSocial: entity.razonSocial,
        nit: entity.nit,
        codCiudad: entity.codCiudad,
        datoCiudad: entity.datoCiudad,
        esVigente: entity.esVigente,
        codEmpresa: entity.codEmpresa,
        audUsuario: entity.audUsuario,
        nombreCompleto: entity.nombreCompleto,
      );
}
