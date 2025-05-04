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
  final int idCM;
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
  final String maquina;
  final String nombreCompleto;


  ControlCombustibleMaquinaMontacargaModel({
    required this.idCM,
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
    required this.maquina,
    required this.nombreCompleto,
  });

  factory ControlCombustibleMaquinaMontacargaModel.fromJson(
    Map<String, dynamic> json,
  ) => ControlCombustibleMaquinaMontacargaModel(
    idCM: json["idCM"] ?? 0,
    idMaquina: json["idMaquina"] ?? 0,
    fecha: json["fecha"] != null ? DateTime.parse(json["fecha"]) : DateTime.now(),
    litrosIngreso: json["litrosIngreso"]?.toDouble() ?? 0.0,
    litrosSalida: json["litrosSalida"]?.toDouble() ?? 0.0,
    saldoLitros: json["saldoLitros"]?.toDouble() ?? 0.0,
    horasUso: json["horasUso"]?.toDouble() ?? 0.0,
    horometro: json["horometro"]?.toDouble() ?? 0.0,
    codEmpleado: json["codEmpleado"] ?? 0,
    codAlmacen: json["codAlmacen"] ?? "",
    obs: json["obs"] ?? "",
    audUsuario: json["audUsuario"] ?? 0,
    whsCode: json["whsCode"] ?? "",
    whsName: json["whsName"] ?? "",
    maquina: json["maquina"] ?? "",
    nombreCompleto: json["nombreCompleto"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "idCM": idCM,
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
    // audFecha se establece en el servidor
    "whsCode": whsCode,
    "whsName": whsName,
    "maquina": maquina,
    "nombreCompleto": nombreCompleto,
  };

  // Método para convertir de Model a Entity
  ControlCombustibleMaquinaMontacargaEntity toEntity() =>
      ControlCombustibleMaquinaMontacargaEntity(
        idCM: idCM,
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
        maquina: maquina,
        nombreCompleto: nombreCompleto,
        
      );

  // Método factory para convertir de Entity a Model
  factory ControlCombustibleMaquinaMontacargaModel.fromEntity(
    ControlCombustibleMaquinaMontacargaEntity entity,
  ) => ControlCombustibleMaquinaMontacargaModel(
    idCM: entity.idCM,
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
    maquina: entity.maquina,
    nombreCompleto: entity.nombreCompleto,

  );
}
