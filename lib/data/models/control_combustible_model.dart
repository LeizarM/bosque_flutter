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
    final int audUsuario;
    final String coche;
    final double kilometrajeAnterior;

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
        required this.audUsuario,
        required this.coche,
        required this.kilometrajeAnterior,
    });

    factory CombustibleControlModel.fromJson(Map<String, dynamic> json) => CombustibleControlModel(
        idC: json["idC"],
        idCoche: json["idCoche"],
        fecha: DateTime.parse(json["fecha"]),
        estacionServicio: json["estacionServicio"],
        nroFactura: json["nroFactura"],
        importe: json["importe"]?.toDouble(),
        kilometraje: json["kilometraje"]?.toDouble(),
        codEmpleado: json["codEmpleado"],
        diferencia: json["diferencia"]?.toDouble(),
        codSucursalCoche: json["codSucursalCoche"],
        obs: json["obs"],
        litros: json["litros"]?.toDouble(),
        tipoCombustible: json["tipoCombustible"],
        audUsuario: json["audUsuario"],
        coche: json["coche"],
        kilometrajeAnterior: json["kilometrajeAnterior"]?.toDouble(),
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
        "audUsuario": audUsuario,
        "coche": coche,
        "kilometrajeAnterior": kilometrajeAnterior,
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
      audUsuario: audUsuario,
      coche: coche,
      kilometrajeAnterior: kilometrajeAnterior,
    );
}