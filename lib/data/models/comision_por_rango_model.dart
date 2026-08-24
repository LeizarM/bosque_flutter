import 'dart:convert';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';

ComisionPorRangoModel comisionPorRangoModelFromJson(String str) =>
    ComisionPorRangoModel.fromJson(json.decode(str));

String comisionPorRangoModelToJson(ComisionPorRangoModel data) =>
    json.encode(data.toJson());

class ComisionPorRangoModel {
  BigInt idCfr;
  double comision;
  double comisionVisual;
  int min;
  int max;
  String tipo;
  int esInterno;
  BigInt audUsuario;

  ComisionPorRangoModel({
    required this.idCfr,
    required this.comision,
    required this.comisionVisual,
    required this.min,
    required this.max,
    required this.tipo,
    required this.esInterno,
    required this.audUsuario,
  });

  factory ComisionPorRangoModel.fromJson(Map<String, dynamic> json) =>
      ComisionPorRangoModel(
        idCfr: json["idCFR"] != null ? BigInt.from(json["idCFR"]) : BigInt.zero,
        comision: (json["comision"] as num?)?.toDouble() ?? 0.0,
        comisionVisual: (json["comisionVisual"] as num?)?.toDouble() ?? 0.0,
        min: json["min"] ?? 0,
        max: json["max"] ?? 0,
        tipo: json["tipo"] ?? '',
        esInterno: json["esInterno"] ?? 1,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
      );

  // comisionVisual no se envia: es un calculo del SP para mostrar.
  Map<String, dynamic> toJson() => {
    "idCFR": idCfr.toInt(),
    "comision": comision,
    "min": min,
    "max": max,
    "tipo": tipo,
    "esInterno": esInterno,
    "audUsuario": audUsuario.toInt(),
  };

  ComisionPorRangoEntity toEntity() => ComisionPorRangoEntity(
    idCfr: idCfr,
    comision: comision,
    comisionVisual: comisionVisual,
    min: min,
    max: max,
    tipo: tipo,
    esInterno: esInterno,
    audUsuario: audUsuario,
  );

  factory ComisionPorRangoModel.fromEntity(ComisionPorRangoEntity e) =>
      ComisionPorRangoModel(
        idCfr: e.idCfr,
        comision: e.comision,
        comisionVisual: e.comisionVisual,
        min: e.min,
        max: e.max,
        tipo: e.tipo,
        esInterno: e.esInterno,
        audUsuario: e.audUsuario,
      );
}
