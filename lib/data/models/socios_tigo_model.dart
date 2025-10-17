// To parse this JSON data, do
//
//     final sociosTigoModel = sociosTigoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/socio_tigo_entity.dart';

List<SociosTigoModel> sociosTigoModelFromJson(String str) => List<SociosTigoModel>.from(json.decode(str).map((x) => SociosTigoModel.fromJson(x)));

String sociosTigoModelToJson(List<SociosTigoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SociosTigoModel {
    final int codCuenta;
    final int telefono;
    final int? codEmpleado;
    final String nombreCompleto;
    final String? descripcion;
    final String periodoCobrado;
    final int audUsuario;

    SociosTigoModel({
        required this.codCuenta,
        required this.telefono,
        required this.codEmpleado,
        required this.nombreCompleto,
        required this.descripcion,
        required this.periodoCobrado,
        required this.audUsuario,
    });

    factory SociosTigoModel.fromJson(Map<String, dynamic> json) => SociosTigoModel(
        codCuenta: json["codCuenta"]?? 0,
        telefono: json["telefono"]?? 0,
        codEmpleado: json["codEmpleado"]?? 0,
        nombreCompleto: json["nombreCompleto"]??'',
        descripcion: json["descripcion"]??'',
        periodoCobrado: json["periodoCobrado"]??'',
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codCuenta": codCuenta,
        "telefono": telefono,
        "codEmpleado": codEmpleado,
        "nombreCompleto": nombreCompleto,
        "descripcion": descripcion,
        "periodoCobrado": periodoCobrado,
        "audUsuario": audUsuario,
    };
    SocioTigoEntity toEntity ()=> SocioTigoEntity(
      codCuenta: codCuenta,
      telefono: telefono,
      codEmpleado: codEmpleado,
      nombreCompleto: nombreCompleto,
      descripcion: descripcion,
      periodoCobrado: periodoCobrado,
      audUsuario: audUsuario,
    );
    factory SociosTigoModel.fromEntity(SocioTigoEntity entity) => SociosTigoModel(
      codCuenta: entity.codCuenta,
      telefono: entity.telefono,
      codEmpleado: entity.codEmpleado,
      nombreCompleto: entity.nombreCompleto,
      descripcion: entity.descripcion,
      periodoCobrado: entity.periodoCobrado,
      audUsuario: entity.audUsuario,
    );
    
}

