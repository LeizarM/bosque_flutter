import 'dart:convert';
import 'package:bosque_flutter/domain/entities/estado_periodo_entity.dart';

EstadoPeriodoModel estadoPeriodoModelFromJson(String str) =>
    EstadoPeriodoModel.fromJson(json.decode(str));

String estadoPeriodoModelToJson(EstadoPeriodoModel data) =>
    json.encode(data.toJson());

class EstadoPeriodoModel {
  int mes;
  int anio;
  int esInterno;
  int ejecutado;
  int cantidadPagados;
  DateTime? fechaEjecucion;
  double totalComision;

  EstadoPeriodoModel({
    required this.mes,
    required this.anio,
    required this.esInterno,
    required this.ejecutado,
    required this.cantidadPagados,
    this.fechaEjecucion,
    required this.totalComision,
  });

  factory EstadoPeriodoModel.fromJson(Map<String, dynamic> json) =>
      EstadoPeriodoModel(
        mes: json["mes"] ?? 0,
        anio: json["anio"] ?? 0,
        esInterno: json["esInterno"] ?? 0,
        ejecutado: json["ejecutado"] ?? 0,
        cantidadPagados: json["cantidadPagados"] ?? 0,
        // Nulo real: un periodo sin ejecutar no tiene fecha de ejecucion.
        fechaEjecucion:
            json["fechaEjecucion"] != null
                ? DateTime.parse(json["fechaEjecucion"])
                : null,
        totalComision: (json["totalComision"] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    "mes": mes,
    "anio": anio,
    "esInterno": esInterno,
    "ejecutado": ejecutado,
    "cantidadPagados": cantidadPagados,
    "totalComision": totalComision,
  };

  EstadoPeriodoEntity toEntity() => EstadoPeriodoEntity(
    mes: mes,
    anio: anio,
    esInterno: esInterno,
    ejecutado: ejecutado,
    cantidadPagados: cantidadPagados,
    fechaEjecucion: fechaEjecucion,
    totalComision: totalComision,
  );
}
