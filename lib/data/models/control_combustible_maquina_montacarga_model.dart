// To parse this JSON data, do
//
//     final controlCombustibleMaquinaMontacargaModel = controlCombustibleMaquinaMontacargaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';

ControlCombustibleMaquinaMontacargaModel
controlCombustibleMaquinaMontacargaModelFromJson(String str) =>
    ControlCombustibleMaquinaMontacargaModel.fromJson(json.decode(str));

String controlCombustibleMaquinaMontacargaModelToJson(
  ControlCombustibleMaquinaMontacargaModel data,
) => json.encode(data.toJson());

class ControlCombustibleMaquinaMontacargaModel {
  final int idCm;
  final int idMaquina;
  final DateTime fecha;
  final double litrosIngreso;
  final double litrosSalida;
  final double saldoLitros;
  final double horasUso;
  final double horometro;
  final int codEmpleado;
  final String codAlmacen;
  final String obs;
  final int audUsuario;
  final String whsCode;
  final String whsName;

  ControlCombustibleMaquinaMontacargaModel({
    required this.idCm,
    required this.idMaquina,
    required this.fecha,
    required this.litrosIngreso,
    required this.litrosSalida,
    required this.saldoLitros,
    required this.horasUso,
    required this.horometro,
    required this.codEmpleado,
    required this.codAlmacen,
    required this.obs,
    required this.audUsuario,
    required this.whsCode,
    required this.whsName,
  });

  factory ControlCombustibleMaquinaMontacargaModel.fromJson(
    Map<String, dynamic> json,
  ) => ControlCombustibleMaquinaMontacargaModel(
    idCm: json["idCM"],
    idMaquina: json["idMaquina"],
    fecha: DateTime.parse(json["fecha"]),
    litrosIngreso: json["litrosIngreso"]?.toDouble(),
    litrosSalida: json["litrosSalida"]?.toDouble(),
    saldoLitros: json["saldoLitros"]?.toDouble(),
    horasUso: json["horasUso"]?.toDouble(),
    horometro: json["horometro"]?.toDouble(),
    codEmpleado: json["codEmpleado"],
    codAlmacen: json["codAlmacen"],
    obs: json["obs"],
    audUsuario: json["audUsuario"],
    whsCode: json["WhsCode"],
    whsName: json["WhsName"],
  );

  Map<String, dynamic> toJson() => {
    "idCM": idCm,
    "idMaquina": idMaquina,
    "fecha": fecha.toIso8601String(),
    "litrosIngreso": litrosIngreso,
    "litrosSalida": litrosSalida,
    "saldoLitros": saldoLitros,
    "horasUso": horasUso,
    "horometro": horometro,
    "codEmpleado": codEmpleado,
    "codAlmacen": codAlmacen,
    "obs": obs,
    "audUsuario": audUsuario,
    "WhsCode": whsCode,
    "WhsName": whsName,
  };

  // Método para convertir de Model a Entity
  ControlCombustibleMaquinaMontacargaEntity toEntity() =>
      ControlCombustibleMaquinaMontacargaEntity(
        idCm: idCm,
        idMaquina: idMaquina,
        fecha: fecha,
        litrosIngreso: litrosIngreso,
        litrosSalida: litrosSalida,
        saldoLitros: saldoLitros,
        horasUso: horasUso,
        horometro: horometro,
        codEmpleado: codEmpleado,
        codAlmacen: codAlmacen,
        obs: obs,
        audUsuario: audUsuario,
        whsCode: whsCode,
        whsName: whsName,
      );

  // Método factory para convertir de Entity a Model
  factory ControlCombustibleMaquinaMontacargaModel.fromEntity(
    ControlCombustibleMaquinaMontacargaEntity entity,
  ) => ControlCombustibleMaquinaMontacargaModel(
    idCm: entity.idCm,
    idMaquina: entity.idMaquina,
    fecha: entity.fecha,
    litrosIngreso: entity.litrosIngreso,
    litrosSalida: entity.litrosSalida,
    saldoLitros: entity.saldoLitros,
    horasUso: entity.horasUso,
    horometro: entity.horometro,
    codEmpleado: entity.codEmpleado,
    codAlmacen: entity.codAlmacen,
    obs: entity.obs,
    audUsuario: entity.audUsuario,
    whsCode: entity.whsCode,
    whsName: entity.whsName,
  );
}
