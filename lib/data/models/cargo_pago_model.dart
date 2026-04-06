import 'dart:convert';
import 'package:bosque_flutter/domain/entities/cargo_pago_entity.dart';

CargoPagoModel cargoPagoModelFromJson(String str) =>
    CargoPagoModel.fromJson(json.decode(str));

String cargoPagoModelToJson(CargoPagoModel data) => json.encode(data.toJson());

class CargoPagoModel {
  BigInt idCargo;
  BigInt idCotizacion;
  BigInt idTransaccion;
  BigInt idTipoCargo;
  double baseCalculo;
  String origenBase;
  double porcentaje;
  double valorFijo;
  double montoCargo;
  int idMoneda;
  int orden;
  String descripcion;
  int audUsuario;

  CargoPagoModel({
    required this.idCargo,
    required this.idCotizacion,
    required this.idTransaccion,
    required this.idTipoCargo,
    required this.baseCalculo,
    required this.origenBase,
    required this.porcentaje,
    required this.valorFijo,
    required this.montoCargo,
    required this.idMoneda,
    required this.orden,
    required this.descripcion,
    required this.audUsuario,
  });

  factory CargoPagoModel.fromJson(Map<String, dynamic> json) => CargoPagoModel(
    idCargo:
        json["idCargo"] != null ? BigInt.from(json["idCargo"]) : BigInt.zero,
    idCotizacion:
        json["idCotizacion"] != null
            ? BigInt.from(json["idCotizacion"])
            : BigInt.zero,
    idTransaccion:
        json["idTransaccion"] != null
            ? BigInt.from(json["idTransaccion"])
            : BigInt.zero,
    idTipoCargo:
        json["idTipoCargo"] != null
            ? BigInt.from(json["idTipoCargo"])
            : BigInt.zero,
    baseCalculo: json["baseCalculo"]?.toDouble() ?? 0.0,
    origenBase: json["origenBase"] ?? '',
    porcentaje: json["porcentaje"]?.toDouble() ?? 0.0,
    valorFijo: json["valorFijo"]?.toDouble() ?? 0.0,
    montoCargo: json["montoCargo"]?.toDouble() ?? 0.0,
    idMoneda: json["idMoneda"] ?? 0,
    orden: json["orden"] ?? 0,
    descripcion: json["descripcion"] ?? '',
    audUsuario: json["audUsuario"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "idCargo": idCargo.toInt(),
    "idCotizacion": idCotizacion.toInt(),
    "idTransaccion": idTransaccion.toInt(),
    "idTipoCargo": idTipoCargo.toInt(),
    "baseCalculo": baseCalculo,
    "origenBase": origenBase,
    "porcentaje": porcentaje,
    "valorFijo": valorFijo,
    "montoCargo": montoCargo,
    "idMoneda": idMoneda,
    "orden": orden,
    "descripcion": descripcion,
    "audUsuario": audUsuario,
  };

  CargoPagoEntity toEntity() => CargoPagoEntity(
    idCargo: idCargo,
    idCotizacion: idCotizacion,
    idTransaccion: idTransaccion,
    idTipoCargo: idTipoCargo,
    baseCalculo: baseCalculo,
    origenBase: origenBase,
    porcentaje: porcentaje,
    valorFijo: valorFijo,
    montoCargo: montoCargo,
    idMoneda: idMoneda,
    orden: orden,
    descripcion: descripcion,
    audUsuario: audUsuario,
  );

  factory CargoPagoModel.fromEntity(CargoPagoEntity entity) => CargoPagoModel(
    idCargo: entity.idCargo,
    idCotizacion: entity.idCotizacion,
    idTransaccion: entity.idTransaccion,
    idTipoCargo: entity.idTipoCargo,
    baseCalculo: entity.baseCalculo,
    origenBase: entity.origenBase,
    porcentaje: entity.porcentaje,
    valorFijo: entity.valorFijo,
    montoCargo: entity.montoCargo,
    idMoneda: entity.idMoneda,
    orden: entity.orden,
    descripcion: entity.descripcion,
    audUsuario: entity.audUsuario,
  );
}
