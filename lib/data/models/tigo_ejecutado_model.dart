// To parse this JSON data, do
//
//     final tigoEjecutadoModel = tigoEjecutadoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';

List<TigoEjecutadoModel> tigoEjecutadoModelFromJson(String str) => List<TigoEjecutadoModel>.from(json.decode(str).map((x) => TigoEjecutadoModel.fromJson(x)));

String tigoEjecutadoModelToJson(List<TigoEjecutadoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TigoEjecutadoModel {
    final int codCuenta;
    final String? corporativo;
    final int codEmpleado;
    final String nombreCompleto;
    final String? ciNumero;
    final String? descripcion;
    final String periodoCobrado;
    final String empresa;
    final int totalCobradoXCuenta;
    final double montoCubiertoXEmpresa;
    final double montoEmpleado;
    final dynamic estado;
    final int audUsuario;
    final int fila;
    final int codEmpleadoPadre;
    final List<TigoEjecutadoModel> items;

    TigoEjecutadoModel({
        required this.codCuenta,
        required this.corporativo,
        required this.codEmpleado,
        required this.nombreCompleto,
        required this.ciNumero,
        required this.descripcion,
        required this.periodoCobrado,
        required this.empresa,
        required this.totalCobradoXCuenta,
        required this.montoCubiertoXEmpresa,
        required this.montoEmpleado,
        required this.estado,
        required this.audUsuario,
        required this.fila,
        required this.codEmpleadoPadre,
        required this.items,
    });

    factory TigoEjecutadoModel.fromJson(Map<String, dynamic> json) => TigoEjecutadoModel(
        codCuenta: json["codCuenta"]??0,
        corporativo: json["corporativo"]??'',
        codEmpleado: json["codEmpleado"]??0,
        nombreCompleto: json["nombreCompleto"]??'',
        ciNumero: json["ciNumero"]??'',
        descripcion: json["descripcion"]??'',
        periodoCobrado: json["periodoCobrado"]??'',
        empresa: json["empresa"]??'',
        totalCobradoXCuenta: json["totalCobradoXCuenta"]??0,
        montoCubiertoXEmpresa: json["montoCubiertoXEmpresa"]?.toDouble()??0.0,
        montoEmpleado: json["montoEmpleado"]?.toDouble()??0.0,
        estado: json["estado"]??'',
        audUsuario: json["audUsuario"]??0,
        fila: json["fila"]??0,
        codEmpleadoPadre: json["codEmpleadoPadre"]??0,
        items: (json["items"] != null && (json["items"] as List).isNotEmpty)
    ? List<TigoEjecutadoModel>.from(
        (json["items"] as List).map((x) => TigoEjecutadoModel.fromJson(x)))
    : [],
    );

    Map<String, dynamic> toJson() => {
        "codCuenta": codCuenta,
        "corporativo": corporativo,
        "codEmpleado": codEmpleado,
        "nombreCompleto": nombreCompleto,
        "ciNumero": ciNumero,
        "descripcion": descripcion,
        "periodoCobrado": periodoCobrado,
        "empresa": empresa,
        "totalCobradoXCuenta": totalCobradoXCuenta,
        "montoCubiertoXEmpresa": montoCubiertoXEmpresa,
        "montoEmpleado": montoEmpleado,
        "estado": estado,
        "audUsuario": audUsuario,
        "fila": fila,
        "codEmpleadoPadre": codEmpleadoPadre,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
    };
    TigoEjecutadoEntity toEntity()=> TigoEjecutadoEntity(
      codCuenta: codCuenta,
      corporativo: corporativo??'',
      codEmpleado: codEmpleado,
      nombreCompleto: nombreCompleto,
      descripcion: descripcion ?? '',
      ciNumero: ciNumero??'',
      empresa: empresa,
      periodoCobrado: periodoCobrado,
      estado: estado ?? '',
      totalCobradoXCuenta: totalCobradoXCuenta.toDouble(),
      montoCubiertoXEmpresa: montoCubiertoXEmpresa,
      montoEmpleado: montoEmpleado,
      audUsuario: audUsuario,
      fila: fila,
      codEmpleadoPadre: codEmpleadoPadre,
      items: items.map((item) => item.toEntity()).toList(),
    );
    factory TigoEjecutadoModel.fromEntity(TigoEjecutadoEntity entity) => TigoEjecutadoModel(
      codCuenta: entity.codCuenta,
      corporativo: entity.corporativo.toString(),
      codEmpleado: entity.codEmpleado,
      nombreCompleto:  entity.nombreCompleto,
      descripcion: entity.descripcion,
      ciNumero: entity.ciNumero??'',
      empresa: entity.empresa??'',
      periodoCobrado: entity.periodoCobrado,
      estado: entity.estado,
      totalCobradoXCuenta: entity.totalCobradoXCuenta.toInt(),
      montoCubiertoXEmpresa: entity.montoCubiertoXEmpresa,
      montoEmpleado: entity.montoEmpleado,
      audUsuario: entity.audUsuario,
      fila: entity.fila,
      codEmpleadoPadre: entity.codEmpleadoPadre,
      items: entity.items.map((item) => TigoEjecutadoModel.fromEntity(item)).toList(),
    );
}
