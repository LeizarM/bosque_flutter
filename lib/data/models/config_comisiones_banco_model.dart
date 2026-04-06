import 'dart:convert';
import 'package:bosque_flutter/domain/entities/config_comisiones_banco_entity.dart';

ConfigComisionesBancoModel configComisionesBancoModelFromJson(String str) =>
    ConfigComisionesBancoModel.fromJson(json.decode(str));

String configComisionesBancoModelToJson(ConfigComisionesBancoModel data) =>
    json.encode(data.toJson());

class ConfigComisionesBancoModel {
  BigInt idConfig;
  int codBanco;
  BigInt idTipoTransaccion;
  BigInt idTipoCargo;
  double valorPorcentaje;
  double valorFijo;
  int idMoneda;
  int orden;
  String baseCalculo;
  int activo;
  DateTime fechaVigenciaDesde;
  DateTime fechaVigenciaHasta;
  int audUsuario;

  ConfigComisionesBancoModel({
    required this.idConfig,
    required this.codBanco,
    required this.idTipoTransaccion,
    required this.idTipoCargo,
    required this.valorPorcentaje,
    required this.valorFijo,
    required this.idMoneda,
    required this.orden,
    required this.baseCalculo,
    required this.activo,
    required this.fechaVigenciaDesde,
    required this.fechaVigenciaHasta,
    required this.audUsuario,
  });

  factory ConfigComisionesBancoModel.fromJson(Map<String, dynamic> json) =>
      ConfigComisionesBancoModel(
        idConfig:
            json["idConfig"] != null
                ? BigInt.from(json["idConfig"])
                : BigInt.zero,
        codBanco: json["codBanco"] ?? 0,
        idTipoTransaccion:
            json["idTipoTransaccion"] != null
                ? BigInt.from(json["idTipoTransaccion"])
                : BigInt.zero,
        idTipoCargo:
            json["idTipoCargo"] != null
                ? BigInt.from(json["idTipoCargo"])
                : BigInt.zero,
        valorPorcentaje: json["valorPorcentaje"]?.toDouble() ?? 0.0,
        valorFijo: json["valorFijo"]?.toDouble() ?? 0.0,
        idMoneda: json["idMoneda"] ?? 0,
        orden: json["orden"] ?? 0,
        baseCalculo: json["baseCalculo"] ?? '',
        activo: json["activo"] ?? 0,
        fechaVigenciaDesde:
            json["fechaVigenciaDesde"] != null
                ? DateTime.parse(json["fechaVigenciaDesde"])
                : DateTime.now(),
        fechaVigenciaHasta:
            json["fechaVigenciaHasta"] != null
                ? DateTime.parse(json["fechaVigenciaHasta"])
                : DateTime.now(),
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idConfig": idConfig.toInt(),
    "codBanco": codBanco,
    "idTipoTransaccion": idTipoTransaccion.toInt(),
    "idTipoCargo": idTipoCargo.toInt(),
    "valorPorcentaje": valorPorcentaje,
    "valorFijo": valorFijo,
    "idMoneda": idMoneda,
    "orden": orden,
    "baseCalculo": baseCalculo,
    "activo": activo,
    "fechaVigenciaDesde": fechaVigenciaDesde
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "fechaVigenciaHasta": fechaVigenciaHasta
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "audUsuario": audUsuario,
  };

  ConfigComisionesBancoEntity toEntity() => ConfigComisionesBancoEntity(
    idConfig: idConfig,
    codBanco: codBanco,
    idTipoTransaccion: idTipoTransaccion,
    idTipoCargo: idTipoCargo,
    valorPorcentaje: valorPorcentaje,
    valorFijo: valorFijo,
    idMoneda: idMoneda,
    orden: orden,
    baseCalculo: baseCalculo,
    activo: activo,
    fechaVigenciaDesde: fechaVigenciaDesde,
    fechaVigenciaHasta: fechaVigenciaHasta,
    audUsuario: audUsuario,
  );

  factory ConfigComisionesBancoModel.fromEntity(
    ConfigComisionesBancoEntity entity,
  ) => ConfigComisionesBancoModel(
    idConfig: entity.idConfig,
    codBanco: entity.codBanco,
    idTipoTransaccion: entity.idTipoTransaccion,
    idTipoCargo: entity.idTipoCargo,
    valorPorcentaje: entity.valorPorcentaje,
    valorFijo: entity.valorFijo,
    idMoneda: entity.idMoneda,
    orden: entity.orden,
    baseCalculo: entity.baseCalculo,
    activo: entity.activo,
    fechaVigenciaDesde: entity.fechaVigenciaDesde,
    fechaVigenciaHasta: entity.fechaVigenciaHasta,
    audUsuario: entity.audUsuario,
  );
}
