// To parse this JSON data, do
//
//     final bancoModel = bancoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/banco_entity.dart';

List<BancoModel> bancoModelFromJson(String str) =>
    List<BancoModel>.from(json.decode(str).map((x) => BancoModel.fromJson(x)));

String bancoModelToJson(List<BancoModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BancoModel {
  final int codBanco;
  final String nombre;
  final int audUsuario;
  final int fila;
  final int cheques;
  final int cuentasEmpresa;
  final int cuentasEmpleados;
  final int movimientos;
  final int pagosExterior;

  BancoModel({
    required this.codBanco,
    required this.nombre,
    required this.audUsuario,
    required this.fila,
    this.cheques = 0,
    this.cuentasEmpresa = 0,
    this.cuentasEmpleados = 0,
    this.movimientos = 0,
    this.pagosExterior = 0,
  });

  factory BancoModel.fromJson(Map<String, dynamic> json) => BancoModel(
    codBanco: json["codBanco"] ?? 0,
    nombre: json["nombre"] ?? '',
    audUsuario: json["audUsuario"] ?? 0,
    fila: json["fila"] ?? 0,
    cheques: json["cheques"] ?? 0,
    cuentasEmpresa: json["cuentasEmpresa"] ?? 0,
    cuentasEmpleados: json["cuentasEmpleados"] ?? 0,
    movimientos: json["movimientos"] ?? 0,
    pagosExterior: json["pagosExterior"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "codBanco": codBanco,
    "nombre": nombre,
    "audUsuario": audUsuario,
    "fila": fila,
    "cheques": cheques,
    "cuentasEmpresa": cuentasEmpresa,
    "cuentasEmpleados": cuentasEmpleados,
    "movimientos": movimientos,
    "pagosExterior": pagosExterior,
  };
  BancoEntity toEntity() => BancoEntity(
    codBanco: codBanco,
    nombre: nombre,
    audUsuario: audUsuario,
    fila: fila,
    cheques: cheques,
    cuentasEmpresa: cuentasEmpresa,
    cuentasEmpleados: cuentasEmpleados,
    movimientos: movimientos,
    pagosExterior: pagosExterior,
  );
  factory BancoModel.fromEntity(BancoEntity entity) => BancoModel(
    codBanco: entity.codBanco,
    nombre: entity.nombre,
    audUsuario: entity.audUsuario,
    fila: entity.fila,
    cheques: entity.cheques,
    cuentasEmpresa: entity.cuentasEmpresa,
    cuentasEmpleados: entity.cuentasEmpleados,
    movimientos: entity.movimientos,
    pagosExterior: entity.pagosExterior,
  );
}
