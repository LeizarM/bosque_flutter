import 'dart:convert';
import 'package:bosque_flutter/domain/entities/grupo_comision_entity.dart';

GrupoComisionModel grupoComisionModelFromJson(String str) =>
    GrupoComisionModel.fromJson(json.decode(str));

String grupoComisionModelToJson(GrupoComisionModel data) =>
    json.encode(data.toJson());

class GrupoComisionModel {
  BigInt idGrupo;
  String grupo;
  double porcentaje;
  int esParaVenta;
  int esInterno;
  int? bd;
  String siglaEmpresa;
  int activo;
  BigInt audUsuario;

  GrupoComisionModel({
    required this.idGrupo,
    required this.grupo,
    required this.porcentaje,
    required this.esParaVenta,
    required this.esInterno,
    this.bd,
    required this.siglaEmpresa,
    required this.activo,
    required this.audUsuario,
  });

  factory GrupoComisionModel.fromJson(Map<String, dynamic> json) =>
      GrupoComisionModel(
        idGrupo:
            json["idGrupo"] != null
                ? BigInt.from(json["idGrupo"])
                : BigInt.zero,
        grupo: json["grupo"] ?? '',
        porcentaje: (json["porcentaje"] as num?)?.toDouble() ?? 0.0,
        esParaVenta: json["esParaVenta"] ?? 0,
        esInterno: json["esInterno"] ?? 0,
        bd: json["bd"],
        siglaEmpresa: json["siglaEmpresa"] ?? '',
        activo: json["activo"] ?? 0,
        audUsuario:
            json["audUsuario"] != null
                ? BigInt.from(json["audUsuario"])
                : BigInt.zero,
      );

  Map<String, dynamic> toJson() => {
    "idGrupo": idGrupo.toInt(),
    "grupo": grupo,
    "porcentaje": porcentaje,
    "esParaVenta": esParaVenta,
    "esInterno": esInterno,
    "bd": bd,
    "activo": activo,
    "audUsuario": audUsuario.toInt(),
  };

  GrupoComisionEntity toEntity() => GrupoComisionEntity(
    idGrupo: idGrupo,
    grupo: grupo,
    porcentaje: porcentaje,
    esParaVenta: esParaVenta,
    esInterno: esInterno,
    bd: bd,
    siglaEmpresa: siglaEmpresa,
    activo: activo,
    audUsuario: audUsuario,
  );

  factory GrupoComisionModel.fromEntity(GrupoComisionEntity entity) =>
      GrupoComisionModel(
        idGrupo: entity.idGrupo,
        grupo: entity.grupo,
        porcentaje: entity.porcentaje,
        esParaVenta: entity.esParaVenta,
        esInterno: entity.esInterno,
        bd: entity.bd,
        siglaEmpresa: entity.siglaEmpresa,
        activo: entity.activo,
        audUsuario: entity.audUsuario,
      );
}
