import 'dart:convert';

import 'package:bosque_flutter/domain/entities/control_combustible_entity.dart';

CombustibleControlModel combustibleControlModelFromJson(String str) => CombustibleControlModel.fromJson(json.decode(str));

String combustibleControlModelToJson(CombustibleControlModel data) => json.encode(data.toJson());

class CombustibleControlModel {
    final int idC;
    final int idCoche;
    final DateTime fecha;
    final String estacionServicio;
    final String nroFactura;
    final double importe;
    final double kilometraje;
    final int codEmpleado;
    final double diferencia;
    final int codSucursalCoche;
    final String obs;
    final double litros;
    final String tipoCombustible;
    final int idCM;
    final int audUsuario;
    final String coche;
    final double kilometrajeAnterior;
    final int esMenor;

    CombustibleControlModel({
        required this.idC,
        required this.idCoche,
        required this.fecha,
        required this.estacionServicio,
        required this.nroFactura,
        required this.importe,
        required this.kilometraje,
        required this.codEmpleado,
        required this.diferencia,
        required this.codSucursalCoche,
        required this.obs,
        required this.litros,
        required this.tipoCombustible,
        required this.idCM,
        required this.audUsuario,
        required this.coche,
        required this.kilometrajeAnterior,
        required this.esMenor,
    });

    factory CombustibleControlModel.fromJson(Map<String, dynamic> json) => CombustibleControlModel(
        idC: json["idC"] ?? 0,
        idCoche: json["idCoche"] ?? 0,
        fecha: json["fecha"] != null && json["fecha"] != '' ? DateTime.parse(json["fecha"]) : DateTime.now(),
        estacionServicio: json["estacionServicio"] ?? '',
        nroFactura: json["nroFactura"] ?? '',
        importe: (json["importe"] ?? 0).toDouble(),
        kilometraje: (json["kilometraje"] ?? 0).toDouble(),
        codEmpleado: json["codEmpleado"] ?? 0,
        diferencia: (json["diferencia"] ?? 0).toDouble(),
        codSucursalCoche: json["codSucursalCoche"] ?? 0,
        obs: json["obs"] ?? '',
        litros: (json["litros"] ?? 0).toDouble(),
        tipoCombustible: json["tipoCombustible"] ?? '',
        idCM: json["idCM"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
        coche: json["coche"] ?? '',
        kilometrajeAnterior: (json["kilometrajeAnterior"] ?? 0).toDouble(),
        esMenor: json["esMenor"] ?? 1,
    );

    Map<String, dynamic> toJson() => {
        "idC": idC,
        "idCoche": idCoche,
        "fecha": fecha.toIso8601String(),
        "estacionServicio": estacionServicio,
        "nroFactura": nroFactura,
        "importe": importe,
        "kilometraje": kilometraje,
        "codEmpleado": codEmpleado,
        "diferencia": diferencia,
        "codSucursalCoche": codSucursalCoche,
        "obs": obs,
        "litros": litros,
        "tipoCombustible": tipoCombustible,
        "idCM": idCM,
        "audUsuario": audUsuario,
        "coche": coche,
        "kilometrajeAnterior": kilometrajeAnterior,
        "esMenor": esMenor,
    };

    //to Entity
    CombustibleControlEntity toEntity() => CombustibleControlEntity(
      idC: idC,
      idCoche: idCoche,
      fecha: fecha,
      estacionServicio: estacionServicio,
      nroFactura: nroFactura,
      importe: importe,
      kilometraje: kilometraje,
      codEmpleado: codEmpleado,
      diferencia: diferencia,
      codSucursalCoche: codSucursalCoche,
      obs: obs,
      litros: litros,
      tipoCombustible: tipoCombustible,
      idCM: idCM,
      audUsuario: audUsuario,
      coche: coche,
      kilometrajeAnterior: kilometrajeAnterior,
      esMenor: esMenor,
    );

  static fromEntity(CombustibleControlEntity data) {
    return CombustibleControlModel(
      idC: data.idC,
      idCoche: data.idCoche,
      fecha: data.fecha,
      estacionServicio: data.estacionServicio,
      nroFactura: data.nroFactura,
      importe: data.importe,
      kilometraje: data.kilometraje,
      codEmpleado: data.codEmpleado,
      diferencia: data.diferencia,
      codSucursalCoche: data.codSucursalCoche,
      obs: data.obs,
      litros: data.litros,
      tipoCombustible: data.tipoCombustible,
      idCM: data.idCM,
      audUsuario: data.audUsuario,
      coche: data.coche,
      kilometrajeAnterior: data.kilometrajeAnterior,
      esMenor: data.esMenor,
    );
  }
}