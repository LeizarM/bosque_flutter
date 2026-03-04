// To parse this JSON data, do
//
//     final sucursalModel = sucursalModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/data/models/empresa_model.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';

SucursalModel sucursalModelFromJson(String str) => SucursalModel.fromJson(json.decode(str));

String sucursalModelToJson(SucursalModel data) => json.encode(data.toJson());

class SucursalModel {
    final int codSucursal;
    final String nombre;
    final int codEmpresa;
    final int codCiudad;
    final int audUsuarioI;
    final EmpresaModel empresa;
    final String nombreCiudad;
    final int codSucursalPlanilla;
    final String nombrePlanilla;

    SucursalModel({
        required this.codSucursal,
        required this.nombre,
        required this.codEmpresa,
        required this.codCiudad,
        required this.audUsuarioI,
        required this.empresa,
        required this.nombreCiudad,
        required this.codSucursalPlanilla,
        required this.nombrePlanilla,
    });

    factory SucursalModel.fromJson(Map<String, dynamic> json) => SucursalModel(
        codSucursal: json["codSucursal"] ?? 0,
        nombre: json["nombre"] ?? "",
        codEmpresa: json["codEmpresa"] ?? 0,
        codCiudad: json["codCiudad"] ?? 0,
        audUsuarioI: json["audUsuarioI"] ?? 0,
        empresa: EmpresaModel.fromJson(json["empresa"]??  {}),
        nombreCiudad: json["nombreCiudad"] ?? "",
        codSucursalPlanilla: json["codSucursalPlanilla"] ?? 0,
        nombrePlanilla: json["nombrePlanilla"] ?? "",
    );

    Map<String, dynamic> toJson() => {
        "codSucursal": codSucursal,
        "nombre": nombre,
        "codEmpresa": codEmpresa,
        "codCiudad": codCiudad,
        "audUsuarioI": audUsuarioI,
        "empresa": empresa.toJson(),
        "nombreCiudad": nombreCiudad,
        "codSucursalPlanilla": codSucursalPlanilla,
        "nombrePlanilla": nombrePlanilla,
    };


   SucursalEntity toEntity() => SucursalEntity(
    codSucursal: codSucursal,
    nombre: nombre,
    codEmpresa: codEmpresa,
    codCiudad: codCiudad,
    audUsuarioI: audUsuarioI,
    empresa: empresa.toEntity(),
    nombreCiudad: nombreCiudad,
    codSucursalPlanilla: codSucursalPlanilla,
    nombrePlanilla: nombrePlanilla,
  );

  // Método factory para convertir de Entity a Model
  factory SucursalModel.fromEntity(SucursalEntity entity) => SucursalModel(
    codSucursal: entity.codSucursal,
    nombre: entity.nombre,
    codEmpresa: entity.codEmpresa,
    codCiudad: entity.codCiudad,
    audUsuarioI: entity.audUsuarioI,
    empresa: EmpresaModel.fromEntity(entity.empresa),
    nombreCiudad: entity.nombreCiudad,
    codSucursalPlanilla: entity.codSucursalPlanilla,
    nombrePlanilla: entity.nombrePlanilla,
  );
}
