// To parse this JSON data, do
//
//     final maquinaMontacargaModel = maquinaMontacargaModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/maquina_montacarga_entity.dart';

MaquinaMontacargaModel maquinaMontacargaModelFromJson(String str) =>
    MaquinaMontacargaModel.fromJson(json.decode(str));

String maquinaMontacargaModelToJson(MaquinaMontacargaModel data) =>
    json.encode(data.toJson());

class MaquinaMontacargaModel {
  final int idMaquina;
  final String codigo;
  final String marca;
  final String clase;
  final int anio;
  final String color;
  final int codSucursal;
  final int estado;
  final int audUsuario;
  final String nombreSucursal;
  final String maquinaOVehiculo;

  MaquinaMontacargaModel({
    required this.idMaquina,
    required this.codigo,
    required this.marca,
    required this.clase,
    required this.anio,
    required this.color,
    required this.codSucursal,
    required this.estado,
    required this.audUsuario,
    required this.nombreSucursal,
    required this.maquinaOVehiculo,
  });

  factory MaquinaMontacargaModel.fromJson(Map<String, dynamic> json) =>
      MaquinaMontacargaModel(
        idMaquina: json["idMaquina"] ?? 0,
        codigo: json["codigo"] ?? '',
        marca: json["marca"] ?? '',
        clase: json["clase"] ?? '',
        anio: json["anio"] ?? 0,
        color: json["color"] ?? '',
        codSucursal: json["codSucursal"] ?? 0,
        estado: json["estado"] ?? 0,
        audUsuario: json["audUsuario"] ?? 0,
        nombreSucursal: json["nombreSucursal"] ?? '',
        maquinaOVehiculo: json["maquinaOVehiculo"] ?? json["maquinaOvehiculo"] ?? '', // Try both possible field names
      );

  Map<String, dynamic> toJson() => {
    "idMaquina": idMaquina,
    "codigo": codigo,
    "marca": marca,
    "clase": clase,
    "anio": anio,
    "color": color,
    "codSucursal": codSucursal,
    "estado": estado,
    "audUsuario": audUsuario,
    "nombreSucursal": nombreSucursal,
    "maquinaOVehiculo": maquinaOVehiculo,
  };

  // Método para convertir de Model a Entity
  MaquinaMontacargaEntity toEntity() => MaquinaMontacargaEntity(
    idMaquina: idMaquina,
    codigo: codigo,
    marca: marca,
    clase: clase,
    anio: anio,
    color: color,
    codSucursal: codSucursal,
    estado: estado,
    audUsuario: audUsuario,
    nombreSucursal: nombreSucursal,
    maquinaOVehiculo: maquinaOVehiculo,
  );

  // Método factory para convertir de Entity a Model
  factory MaquinaMontacargaModel.fromEntity(MaquinaMontacargaEntity entity) =>
      MaquinaMontacargaModel(
        idMaquina: entity.idMaquina,
        codigo: entity.codigo,
        marca: entity.marca,
        clase: entity.clase,
        anio: entity.anio,
        color: entity.color,
        codSucursal: entity.codSucursal,
        estado: entity.estado,
        audUsuario: entity.audUsuario,
        nombreSucursal: entity.nombreSucursal,
        maquinaOVehiculo: entity.maquinaOVehiculo,
      );
}
