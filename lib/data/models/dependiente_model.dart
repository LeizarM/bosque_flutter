// To parse this JSON data, do
//
//     final dependienteModel = dependienteModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';

List<DependienteModel> dependienteModelFromJson(String str) => List<DependienteModel>.from(json.decode(str).map((x) => DependienteModel.fromJson(x)));

String dependienteModelToJson(List<DependienteModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DependienteModel {
    final int codDependiente;
    final int codPersona;
    final int codEmpleado;
    final String parentesco;
    final String esActivo;
    final int audUsuario;
    final String nombreCompleto;
    final dynamic descripcion;
    final int edad;

    DependienteModel({
        required this.codDependiente,
        required this.codPersona,
        required this.codEmpleado,
        required this.parentesco,
        required this.esActivo,
        required this.audUsuario,
        required this.nombreCompleto,
        required this.descripcion,
        required this.edad,
    });

    factory DependienteModel.fromJson(Map<String, dynamic> json) => DependienteModel(
        codDependiente: json["codDependiente"]?? 0,
        codPersona: json["codPersona"]?? 0,
        codEmpleado: json["codEmpleado"]?? 0,
        parentesco: json["parentesco"]??'',
        esActivo: json["esActivo"]??'',
        audUsuario: json["audUsuario"]??0,
        nombreCompleto: json["nombreCompleto"]??'',
        descripcion: json["descripcion"]??'',
        edad: json["edad"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codDependiente": codDependiente,
        "codPersona": codPersona,
        "codEmpleado": codEmpleado,
        "parentesco": parentesco,
        "esActivo": esActivo,
        "audUsuario": audUsuario,
        "nombreCompleto": nombreCompleto,
        "descripcion": descripcion,
        "edad": edad,
    };
    DependienteEntity toEntity()=> DependienteEntity(
        codDependiente: codDependiente,
        codPersona: codPersona,
        codEmpleado: codEmpleado,
        parentesco: parentesco,
        esActivo: esActivo,
        audUsuario: audUsuario,
        nombreCompleto: nombreCompleto,
        descripcion: descripcion,
        edad: edad,
    );
    factory DependienteModel.fromEntity(DependienteEntity entity) => DependienteModel(
        codDependiente: entity.codDependiente,
        codPersona: entity.codPersona,
        codEmpleado: entity.codEmpleado,
        parentesco: entity.parentesco,
        esActivo: entity.esActivo,
        audUsuario: entity.audUsuario,
        nombreCompleto: entity.nombreCompleto,
        descripcion: entity.descripcion,
        edad: entity.edad,
    );
}
