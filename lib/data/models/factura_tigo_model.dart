// To parse this JSON data, do
//
//     final facturaTigoModel = facturaTigoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/factura_tigo_entity.dart';

List<FacturaTigoModel> facturaTigoModelFromJson(String str) => List<FacturaTigoModel>.from(json.decode(str).map((x) => FacturaTigoModel.fromJson(x)));

String facturaTigoModelToJson(List<FacturaTigoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class FacturaTigoModel {
    final int codFactura;
    final String nroFactura;
    final String tipoServicio;
    final String nroContrato;
    final String nroCuenta;
    final String periodoCobrado;
    final String descripcionPlan;
    final double totalCobradoXCuenta;
    final String? estado;
    final int audUsuario;

    FacturaTigoModel({
        required this.codFactura,
        required this.nroFactura,
        required this.tipoServicio,
        required this.nroContrato,
        required this.nroCuenta,
        required this.periodoCobrado,
        required this.descripcionPlan,
        required this.totalCobradoXCuenta,
        required this.estado,
        required this.audUsuario,
    });

    factory FacturaTigoModel.fromJson(Map<String, dynamic> json) => FacturaTigoModel(
      
        codFactura: json["codFactura"]??0,
        nroFactura: json["nroFactura"] != null ? json["nroFactura"].toString() : '',
        tipoServicio: json["tipoServicio"].toString()??'',
        nroContrato: json["nroContrato"].toString()??'',
        nroCuenta: json["nroCuenta"].toString()??'',
        periodoCobrado:  json["periodoCobrado"] ??'',
        descripcionPlan: json["descripcionPlan"]??'',
        totalCobradoXCuenta: json["totalCobradoXCuenta"]??0.0,
        estado: json["estado"]??'',
        audUsuario: json["audUsuario"]??0,
    );

    Map<String, dynamic> toJson() => {
        "codFactura": codFactura,
        "nroFactura": nroFactura,
        "tipoServicio": tipoServicio,
        "nroContrato": nroContrato,
        "nroCuenta": nroCuenta,
        "periodoCobrado": periodoCobrado,
        "descripcionPlan": descripcionPlan,
        "totalCobradoXCuenta": totalCobradoXCuenta,
        "estado": estado,
        "audUsuario": audUsuario,
    };
    FacturaTigoEntity toEntity() => FacturaTigoEntity(
      codFactura: codFactura,
      nroFactura: nroFactura,
      tipoServicio: tipoServicio,
      nroContrato: nroContrato,
      nroCuenta: nroCuenta,
      periodoCobrado: periodoCobrado,
      descripcionPlan: descripcionPlan,
      totalCobradoXCuenta: totalCobradoXCuenta,
      estado: estado,
      audUsuario: audUsuario,
    );
    factory FacturaTigoModel.fromEntity(FacturaTigoEntity entity) => FacturaTigoModel(
      codFactura: entity.codFactura,
      nroFactura: entity.nroFactura,
      tipoServicio: entity.tipoServicio,
      nroContrato: entity.nroContrato,
      nroCuenta: entity.nroCuenta,
      periodoCobrado: entity.periodoCobrado,
      descripcionPlan: entity.descripcionPlan,
      totalCobradoXCuenta: entity.totalCobradoXCuenta,
      estado: entity.estado,
      audUsuario: entity.audUsuario,
    );
}
