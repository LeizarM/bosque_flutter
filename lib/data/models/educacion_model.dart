// To parse this JSON data, do
//
//     final educacionModel = educacionModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/educacion_entity.dart';

List<EducacionModel> educacionModelFromJson(String str) => List<EducacionModel>.from(json.decode(str).map((x) => EducacionModel.fromJson(x)));

String educacionModelToJson(List<EducacionModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class EducacionModel {
    final int codEducacion;
    final int codEmpleado;
    final String tipoEducacion;
    final String descripcion;
    final DateTime fecha;
    final int audUsuario;

    EducacionModel({
        required this.codEducacion,
        required this.codEmpleado,
        required this.tipoEducacion,
        required this.descripcion,
        required this.fecha,
        required this.audUsuario,
    });

    factory EducacionModel.fromJson(Map<String, dynamic> json) => EducacionModel(
        codEducacion: json["codEducacion"]?? 0,
        codEmpleado: json["codEmpleado"]?? 0,
        tipoEducacion: json["tipoEducacion"]??'',
        descripcion: json["descripcion"]??'',
        //fecha: DateTime.parse(json["fecha"]),
        fecha: json["fecha"] != null ? DateTime.parse(json["fecha"]) : DateTime.now(),
        audUsuario: json["audUsuario"]?? 0,
    );

    Map<String, dynamic> toJson() => {
        "codEducacion": codEducacion,
        "codEmpleado": codEmpleado,
        "tipoEducacion": tipoEducacion,
        "descripcion": descripcion,
        //"fecha": "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}",
        "fecha": fecha.toIso8601String(),
        "audUsuario": audUsuario,
    };
    EducacionEntity toEntity () => EducacionEntity(
        codEducacion: codEducacion,
        codEmpleado: codEmpleado,
        tipoEducacion: tipoEducacion,
        descripcion: descripcion,
        fecha: fecha,
        audUsuario: audUsuario,
    );
    factory EducacionModel.fromEntity (EducacionEntity entity) => EducacionModel(
        codEducacion: entity.codEducacion,
        codEmpleado: entity.codEmpleado,
        tipoEducacion: entity.tipoEducacion,
        descripcion: entity.descripcion,
        fecha: entity.fecha,
        audUsuario: entity.audUsuario,
    );

}
