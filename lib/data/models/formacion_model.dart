// To parse this JSON data, do
//
//     final formacionModel = formacionModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/formacion_entity.dart';

List<FormacionModel> formacionModelFromJson(String str) => List<FormacionModel>.from(json.decode(str).map((x) => FormacionModel.fromJson(x)));

String formacionModelToJson(List<FormacionModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class FormacionModel {
    final int codFormacion;
    final int codEmpleado;
    final String descripcion;
    final int duracion;
    final String tipoDuracion;
    final String tipoFormacion;
    final DateTime fechaFormacion;
    final int audUsuario;

    FormacionModel({
        required this.codFormacion,
        required this.codEmpleado,
        required this.descripcion,
        required this.duracion,
        required this.tipoDuracion,
        required this.tipoFormacion,
        required this.fechaFormacion,
        required this.audUsuario,
    });

    factory FormacionModel.fromJson(Map<String, dynamic> json) => FormacionModel(
        codFormacion: json["codFormacion"]?? 0,
        codEmpleado: json["codEmpleado"]?? 0,
        descripcion: json["descripcion"]?? '',
        duracion: json["duracion"]?? 0,
        tipoDuracion: json["tipoDuracion"]?? '',
        tipoFormacion: json["tipoFormacion"]?? '',
        fechaFormacion: json["fechaFormacion"] != null ? DateTime.parse(json["fechaFormacion"]) : DateTime.now(),
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codFormacion": codFormacion,
        "codEmpleado": codEmpleado,
        "descripcion": descripcion,
        "duracion": duracion,
        "tipoDuracion": tipoDuracion,
        "tipoFormacion": tipoFormacion,
        "fechaFormacion": "${fechaFormacion.year.toString().padLeft(4, '0')}-${fechaFormacion.month.toString().padLeft(2, '0')}-${fechaFormacion.day.toString().padLeft(2, '0')}",
        "audUsuario": audUsuario,
    };
    FormacionEntity toEntity() => FormacionEntity(
        codFormacion: codFormacion,
        codEmpleado: codEmpleado,
        descripcion: descripcion,
        duracion: duracion,
        tipoDuracion: tipoDuracion,
        tipoFormacion: tipoFormacion,
        fechaFormacion: fechaFormacion,
        audUsuario: audUsuario,
    );
    factory FormacionModel.fromEntity(FormacionEntity entity) => FormacionModel(
        codFormacion: entity.codFormacion,
        codEmpleado: entity.codEmpleado,
        descripcion: entity.descripcion,
        duracion: entity.duracion,
        tipoDuracion: entity.tipoDuracion,
        tipoFormacion: entity.tipoFormacion,
        fechaFormacion: entity.fechaFormacion,
        audUsuario: entity.audUsuario,
    );
}
