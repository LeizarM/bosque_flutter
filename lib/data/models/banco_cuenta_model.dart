// To parse this JSON data, do
//
//     final bancoXCuentaModel = bancoXCuentaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/banco_cuenta_entity.dart';

BancoXCuentaModel bancoXCuentaModelFromJson(String str) =>
    BancoXCuentaModel.fromJson(json.decode(str));

String bancoXCuentaModelToJson(BancoXCuentaModel data) =>
    json.encode(data.toJson());

class BancoXCuentaModel {
  final int idBxC;
  final int codBanco;
  final String numCuenta;
  final String moneda;
  final int codEmpresa;
  final int audUsuario;
  final String nombreBanco;

  BancoXCuentaModel({
    required this.idBxC,
    required this.codBanco,
    required this.numCuenta,
    required this.moneda,
    required this.codEmpresa,
    required this.audUsuario,
    required this.nombreBanco,
  });

  factory BancoXCuentaModel.fromJson(Map<String, dynamic> json) =>
      BancoXCuentaModel(
        idBxC: json["idBxC"],
        codBanco: json["codBanco"],
        numCuenta: json["numCuenta"],
        moneda: json["moneda"],
        codEmpresa: json["codEmpresa"],
        audUsuario: json["audUsuario"],
        nombreBanco: json["nombreBanco"],
      );

  Map<String, dynamic> toJson() => {
    "idBxC": idBxC,
    "codBanco": codBanco,
    "numCuenta": numCuenta,
    "moneda": moneda,
    "codEmpresa": codEmpresa,
    "audUsuario": audUsuario,
    "nombreBanco": nombreBanco,
  };

  // Método para convertir de Model a Entity
  BancoXCuentaEntity toEntity() => BancoXCuentaEntity(
    idBxC: idBxC,
    codBanco: codBanco,
    numCuenta: numCuenta,
    moneda: moneda,
    codEmpresa: codEmpresa,
    audUsuario: audUsuario,
    nombreBanco: nombreBanco,
  );

  // Método factory para convertir de Entity a Model
  factory BancoXCuentaModel.fromEntity(BancoXCuentaEntity entity) =>
      BancoXCuentaModel(
        idBxC: entity.idBxC,
        codBanco: entity.codBanco,
        numCuenta: entity.numCuenta,
        moneda: entity.moneda,
        codEmpresa: entity.codEmpresa,
        audUsuario: entity.audUsuario,
        nombreBanco: entity.nombreBanco,
      );
}
