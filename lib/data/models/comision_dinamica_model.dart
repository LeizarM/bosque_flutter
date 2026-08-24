import 'dart:convert';
import 'package:bosque_flutter/domain/entities/comision_dinamica_entity.dart';

ComisionDinamicaModel comisionDinamicaModelFromJson(String str) =>
    ComisionDinamicaModel.fromJson(json.decode(str));

String comisionDinamicaModelToJson(ComisionDinamicaModel data) =>
    json.encode(data.toJson());

class ComisionDinamicaModel {
  BigInt idDc;
  int esInterno;
  double metaUsd;
  double metaBs;
  double porcentaje;
  DateTime vigenteDesde;
  DateTime? vigenteHasta;
  BigInt audUsuario;

  ComisionDinamicaModel({
    required this.idDc,
    required this.esInterno,
    required this.metaUsd,
    required this.metaBs,
    required this.porcentaje,
    required this.vigenteDesde,
    this.vigenteHasta,
    required this.audUsuario,
  });

  factory ComisionDinamicaModel.fromJson(Map<String, dynamic> json) =>
      ComisionDinamicaModel(
        idDc: json["idDc"] != null ? BigInt.from(json["idDc"]) : BigInt.zero,
        esInterno: json["esInterno"] ?? 0,
        metaUsd: (json["metaUsd"] as num?)?.toDouble() ?? 0.0,
        metaBs: (json["metaBs"] as num?)?.toDouble() ?? 0.0,
        porcentaje: (json["porcentaje"] as num?)?.toDouble() ?? 0.0,
        vigenteDesde:
            json["vigenteDesde"] != null
                ? DateTime.parse(json["vigenteDesde"])
                : DateTime.now(),
        // Nulo real: sin fecha de fin la escala sigue vigente.
        vigenteHasta:
            json["vigenteHasta"] != null
                ? DateTime.parse(json["vigenteHasta"])
                : null,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
      );

  Map<String, dynamic> toJson() => {
    "idDc": idDc.toInt(),
    "esInterno": esInterno,
    "metaUsd": metaUsd,
    "metaBs": metaBs,
    "porcentaje": porcentaje,
    "vigenteDesde": _fecha(vigenteDesde),
    "vigenteHasta": vigenteHasta != null ? _fecha(vigenteHasta!) : null,
    "audUsuario": audUsuario.toInt(),
  };

  static String _fecha(DateTime f) =>
      f.toIso8601String().substring(0, 19).replaceAll('T', ' ');

  ComisionDinamicaEntity toEntity() => ComisionDinamicaEntity(
    idDc: idDc,
    esInterno: esInterno,
    metaUsd: metaUsd,
    metaBs: metaBs,
    porcentaje: porcentaje,
    vigenteDesde: vigenteDesde,
    vigenteHasta: vigenteHasta,
    audUsuario: audUsuario,
  );

  factory ComisionDinamicaModel.fromEntity(ComisionDinamicaEntity entity) =>
      ComisionDinamicaModel(
        idDc: entity.idDc,
        esInterno: entity.esInterno,
        metaUsd: entity.metaUsd,
        metaBs: entity.metaBs,
        porcentaje: entity.porcentaje,
        vigenteDesde: entity.vigenteDesde,
        vigenteHasta: entity.vigenteHasta,
        audUsuario: entity.audUsuario,
      );
}
