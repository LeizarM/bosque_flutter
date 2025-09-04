// To parse this JSON data, do
//
//     final experienciaLaboralModel = experienciaLaboralModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/experiencia_laboral_entity.dart';

List<ExperienciaLaboralModel> experienciaLaboralModelFromJson(String str) => List<ExperienciaLaboralModel>.from(json.decode(str).map((x) => ExperienciaLaboralModel.fromJson(x)));

String experienciaLaboralModelToJson(List<ExperienciaLaboralModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ExperienciaLaboralModel {
    final int codExperienciaLaboral;
    final int codEmpleado;
    final String nombreEmpresa;
    final String cargo;
    final String descripcion;
    final DateTime fechaInicio;
    final DateTime fechaFin;
    final String nroReferencia;
    final int audUsuario;

    ExperienciaLaboralModel({
        required this.codExperienciaLaboral,
        required this.codEmpleado,
        required this.nombreEmpresa,
        required this.cargo,
        required this.descripcion,
        required this.fechaInicio,
        required this.fechaFin,
        required this.nroReferencia,
        required this.audUsuario,
    });

    factory ExperienciaLaboralModel.fromJson(Map<String, dynamic> json) => ExperienciaLaboralModel(
        codExperienciaLaboral: json["codExperienciaLaboral"]?? 0,
        codEmpleado: json["codEmpleado"]?? 0,
        nombreEmpresa: json["nombreEmpresa"]?? '',
        cargo: json["cargo"]?? '',
        descripcion: json["descripcion"]?? '',
        fechaInicio: json["fechaInicio"] != null ? DateTime.parse(json["fechaInicio"]) : DateTime.now(),
        fechaFin: json["fechaFin"] != null ? DateTime.parse(json["fechaFin"]) : DateTime.now(),
        nroReferencia: json["nroReferencia"]?? '',
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codExperienciaLaboral": codExperienciaLaboral,
        "codEmpleado": codEmpleado,
        "nombreEmpresa": nombreEmpresa,
        "cargo": cargo,
        "descripcion": descripcion,
        "fechaInicio": "${fechaInicio.year.toString().padLeft(4, '0')}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}",
        "fechaFin": "${fechaFin.year.toString().padLeft(4, '0')}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}",
        "nroReferencia": nroReferencia,
        "audUsuario": audUsuario,
    };
    ExperienciaLaboralEntity toEntity() => ExperienciaLaboralEntity(
        codExperienciaLaboral: codExperienciaLaboral,
        codEmpleado: codEmpleado,
        nombreEmpresa: nombreEmpresa,
        cargo: cargo,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        nroReferencia: nroReferencia,
        audUsuario: audUsuario,
    );
    factory ExperienciaLaboralModel.fromEntity(ExperienciaLaboralEntity entity) => ExperienciaLaboralModel(
        codExperienciaLaboral: entity.codExperienciaLaboral,
        codEmpleado: entity.codEmpleado,
        nombreEmpresa: entity.nombreEmpresa,
        cargo: entity.cargo,
        descripcion: entity.descripcion,
        fechaInicio: entity.fechaInicio,
        fechaFin: entity.fechaFin,
        nroReferencia: entity.nroReferencia,
        audUsuario: entity.audUsuario,
    );
}
