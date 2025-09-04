// To parse this JSON data, do
//
//     final relacionLaboralModel = relacionLaboralModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';

List<RelacionLaboralModel> relacionLaboralModelFromJson(String str) => List<RelacionLaboralModel>.from(json.decode(str).map((x) => RelacionLaboralModel.fromJson(x)));

String relacionLaboralModelToJson(List<RelacionLaboralModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class RelacionLaboralModel {
    final int codRelEmplEmpr;
    final int codEmpleado;
    final int esActivo;
    final String tipoRel;
    final String nombreFileContrato;
    final DateTime fechaIni;
    final DateTime fechaFin;
    final String motivoFin;
    final int audUsuario;
    final DateTime fechaInicioBeneficio;
    final DateTime fechaInicioPlanilla;
    final dynamic datoFechasBeneficio;
    final String cargo;
    final String sucursal;
    final String empresaFiscal;
    final String empresaInterna;

    RelacionLaboralModel({
        required this.codRelEmplEmpr,
        required this.codEmpleado,
        required this.esActivo,
        required this.tipoRel,
        required this.nombreFileContrato,
        required this.fechaIni,
        required this.fechaFin,
        required this.motivoFin,
        required this.audUsuario,
        required this.fechaInicioBeneficio,
        required this.fechaInicioPlanilla,
        required this.datoFechasBeneficio,
        required this.cargo,
        required this.sucursal,
        required this.empresaFiscal,
        required this.empresaInterna,
    });

    factory RelacionLaboralModel.fromJson(Map<String, dynamic> json) => RelacionLaboralModel(
        codRelEmplEmpr: json["codRelEmplEmpr"]?? 0,
        codEmpleado: json["codEmpleado"]?? 0,
        esActivo: json["esActivo"]??0,
        tipoRel: json["tipoRel"]?? '',
        nombreFileContrato: json["nombreFileContrato"]?? '',
        fechaIni: json["fechaIni"] != null ? DateTime.parse(json["fechaIni"]) : DateTime.now(),
        fechaFin: json["fechaFin"]!= null ? DateTime.parse(json["fechaFin"]) : DateTime.now(),
        motivoFin: json["motivoFin"]?? '',
        audUsuario: json["audUsuario"]?? 0,
        fechaInicioBeneficio: json["fechaInicioBeneficio"]!= null ? DateTime.parse(json["fechaInicioBeneficio"]) : DateTime.now(),
        fechaInicioPlanilla: json["fechaInicioPlanilla"]!= null ? DateTime.parse(json["fechaInicioPlanilla"]) : DateTime.now(),
        datoFechasBeneficio: json["datoFechasBeneficio"]?? '',
        cargo: json["cargo"]??'',
        sucursal: json["sucursal"]??'',
        empresaFiscal: json["empresaFiscal"]??'',
        empresaInterna: json["empresaInterna"]??'',
    );

    Map<String, dynamic> toJson() => {
        "codRelEmplEmpr": codRelEmplEmpr,
        "codEmpleado": codEmpleado,
        "esActivo": esActivo,
        "tipoRel": tipoRel,
        "nombreFileContrato": nombreFileContrato,
        "fechaIni": "${fechaIni.year.toString().padLeft(4, '0')}-${fechaIni.month.toString().padLeft(2, '0')}-${fechaIni.day.toString().padLeft(2, '0')}",
        "fechaFin": "${fechaFin.year.toString().padLeft(4, '0')}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}",
        "motivoFin": motivoFin,
        "audUsuario": audUsuario,
        "fechaInicioBeneficio": fechaInicioBeneficio,
        "fechaInicioPlanilla": fechaInicioPlanilla,
        "datoFechasBeneficio": datoFechasBeneficio,
        "cargo": cargo,
        "sucursal": sucursal,
        "empresaFiscal": empresaFiscal,
        "empresaInterna": empresaInterna,
    };
    RelacionLaboralEntity toEntity()=> RelacionLaboralEntity(
        codRelEmplEmpr: codRelEmplEmpr,
        codEmpleado: codEmpleado,
        esActivo: esActivo,
        tipoRel: tipoRel,
        nombreFileContrato: nombreFileContrato,
        fechaIni: fechaIni,
        fechaFin: fechaFin,
        motivoFin: motivoFin,
        audUsuario: audUsuario,
        fechaInicioBeneficio: fechaInicioBeneficio,
        fechaInicioPlanilla: fechaInicioPlanilla,
        datoFechasBeneficio: datoFechasBeneficio,
        cargo: cargo,
        sucursal: sucursal,
        empresaFiscal: empresaFiscal,
        empresaInterna: empresaInterna,
    );
    factory RelacionLaboralModel.fromEntity(RelacionLaboralEntity entity)=> RelacionLaboralModel(
        codRelEmplEmpr: entity.codRelEmplEmpr,
        codEmpleado: entity.codEmpleado,
        esActivo: entity.esActivo,
        tipoRel: entity.tipoRel,
        nombreFileContrato: entity.nombreFileContrato,
        fechaIni: entity.fechaIni,
        fechaFin: entity.fechaFin,
        motivoFin: entity.motivoFin,
        audUsuario: entity.audUsuario,
        fechaInicioBeneficio: entity.fechaInicioBeneficio?? DateTime.now(),
        fechaInicioPlanilla: entity.fechaInicioPlanilla ?? DateTime.now(),
        datoFechasBeneficio: entity.datoFechasBeneficio,
        cargo: entity.cargo,
        sucursal: entity.sucursal,
        empresaFiscal: entity.empresaFiscal,
        empresaInterna: entity.empresaInterna,
    );
}
