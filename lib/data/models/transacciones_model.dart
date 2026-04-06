import 'dart:convert';
import 'package:bosque_flutter/data/models/cargo_pago_model.dart';
import 'package:bosque_flutter/domain/entities/transacciones_entity.dart';

TransaccionesModel transaccionesModelFromJson(String str) =>
    TransaccionesModel.fromJson(json.decode(str));

String transaccionesModelToJson(TransaccionesModel data) =>
    json.encode(data.toJson());

class TransaccionesModel {
  BigInt idTransaccion;
  String numeroTransaccion;
  BigInt idSolicitud;
  BigInt idCotizacion;
  BigInt idTipoTransaccion;
  int codBanco;
  int idCanal;
  int codEmpresa;
  String cardCode;
  DateTime fechaTransaccion;
  DateTime fechaValor;
  double montoOrigen;
  int idMonedaOrigen;
  double tipoCambioAplicado;
  double montoConvertido;
  int idMonedaDestino;
  double totalCargos;
  double totalFinal;
  String numeroContrato;
  DateTime fechaPactado;
  DateTime fechaVencimiento;
  double tipoCambioForward;
  double tipoCambioReferencia;
  double equivalenteUsdRef;
  double diferenciaDeMas;
  double porcentajeDiferencia;
  String nombreExportadora;
  double tcNegociadoExportadora;
  double comisionExportadora;
  String metodoExportadora;
  String estado;
  String observaciones;
  int audUsuario;
  List<CargoPagoModel> cargos;

  TransaccionesModel({
    required this.idTransaccion,
    required this.numeroTransaccion,
    required this.idSolicitud,
    required this.idCotizacion,
    required this.idTipoTransaccion,
    required this.codBanco,
    required this.idCanal,
    required this.codEmpresa,
    required this.cardCode,
    required this.fechaTransaccion,
    required this.fechaValor,
    required this.montoOrigen,
    required this.idMonedaOrigen,
    required this.tipoCambioAplicado,
    required this.montoConvertido,
    required this.idMonedaDestino,
    required this.totalCargos,
    required this.totalFinal,
    required this.numeroContrato,
    required this.fechaPactado,
    required this.fechaVencimiento,
    required this.tipoCambioForward,
    required this.tipoCambioReferencia,
    required this.equivalenteUsdRef,
    required this.diferenciaDeMas,
    required this.porcentajeDiferencia,
    required this.nombreExportadora,
    required this.tcNegociadoExportadora,
    required this.comisionExportadora,
    required this.metodoExportadora,
    required this.estado,
    required this.observaciones,
    required this.audUsuario,
    this.cargos = const [],
  });

  factory TransaccionesModel.fromJson(Map<String, dynamic> json) {
    final cargosJson = json["cargos"] as List<dynamic>? ?? [];
    return TransaccionesModel(
      idTransaccion:
          json["idTransaccion"] != null
              ? BigInt.from(json["idTransaccion"])
              : BigInt.zero,
      numeroTransaccion: json["numeroTransaccion"] ?? '',
      idSolicitud:
          json["idSolicitud"] != null
              ? BigInt.from(json["idSolicitud"])
              : BigInt.zero,
      idCotizacion:
          json["idCotizacion"] != null
              ? BigInt.from(json["idCotizacion"])
              : BigInt.zero,
      idTipoTransaccion:
          json["idTipoTransaccion"] != null
              ? BigInt.from(json["idTipoTransaccion"])
              : BigInt.zero,
      codBanco: json["codBanco"] ?? 0,
      idCanal: json["idCanal"] ?? 0,
      codEmpresa: json["codEmpresa"] ?? 0,
      cardCode: json["cardCode"] ?? '',
      fechaTransaccion:
          json["fechaTransaccion"] != null
              ? DateTime.parse(json["fechaTransaccion"])
              : DateTime.now(),
      fechaValor:
          json["fechaValor"] != null
              ? DateTime.parse(json["fechaValor"])
              : DateTime.now(),
      montoOrigen: json["montoOrigen"]?.toDouble() ?? 0.0,
      idMonedaOrigen: json["idMonedaOrigen"] ?? 0,
      tipoCambioAplicado: json["tipoCambioAplicado"]?.toDouble() ?? 0.0,
      montoConvertido: json["montoConvertido"]?.toDouble() ?? 0.0,
      idMonedaDestino: json["idMonedaDestino"] ?? 0,
      totalCargos: json["totalCargos"]?.toDouble() ?? 0.0,
      totalFinal: json["totalFinal"]?.toDouble() ?? 0.0,
      numeroContrato: json["numeroContrato"] ?? '',
      fechaPactado:
          json["fechaPactado"] != null
              ? DateTime.parse(json["fechaPactado"])
              : DateTime.now(),
      fechaVencimiento:
          json["fechaVencimiento"] != null
              ? DateTime.parse(json["fechaVencimiento"])
              : DateTime.now(),
      tipoCambioForward: json["tipoCambioForward"]?.toDouble() ?? 0.0,
      tipoCambioReferencia: json["tipoCambioReferencia"]?.toDouble() ?? 0.0,
      equivalenteUsdRef: json["equivalenteUsdRef"]?.toDouble() ?? 0.0,
      diferenciaDeMas: json["diferenciaDeMas"]?.toDouble() ?? 0.0,
      porcentajeDiferencia: json["porcentajeDiferencia"]?.toDouble() ?? 0.0,
      nombreExportadora: json["nombreExportadora"] ?? '',
      tcNegociadoExportadora: json["tcNegociadoExportadora"]?.toDouble() ?? 0.0,
      comisionExportadora: json["comisionExportadora"]?.toDouble() ?? 0.0,
      metodoExportadora: json["metodoExportadora"] ?? '',
      estado: json["estado"] ?? '',
      observaciones: json["observaciones"] ?? '',
      audUsuario: json["audUsuario"] ?? 0,
      cargos:
          cargosJson
              .map((c) => CargoPagoModel.fromJson(c as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "idTransaccion": idTransaccion.toInt(),
    "numeroTransaccion": numeroTransaccion,
    "idSolicitud": idSolicitud.toInt(),
    "idCotizacion": idCotizacion.toInt(),
    "idTipoTransaccion": idTipoTransaccion.toInt(),
    "codBanco": codBanco,
    "idCanal": idCanal,
    "codEmpresa": codEmpresa,
    "cardCode": cardCode,
    "fechaTransaccion": fechaTransaccion
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "fechaValor": fechaValor
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "montoOrigen": montoOrigen,
    "idMonedaOrigen": idMonedaOrigen,
    "tipoCambioAplicado": tipoCambioAplicado,
    "montoConvertido": montoConvertido,
    "idMonedaDestino": idMonedaDestino,
    "totalCargos": totalCargos,
    "totalFinal": totalFinal,
    "numeroContrato": numeroContrato,
    "fechaPactado": fechaPactado
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "fechaVencimiento": fechaVencimiento
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "tipoCambioForward": tipoCambioForward,
    "tipoCambioReferencia": tipoCambioReferencia,
    "equivalenteUsdRef": equivalenteUsdRef,
    "diferenciaDeMas": diferenciaDeMas,
    "porcentajeDiferencia": porcentajeDiferencia,
    "nombreExportadora": nombreExportadora,
    "tcNegociadoExportadora": tcNegociadoExportadora,
    "comisionExportadora": comisionExportadora,
    "metodoExportadora": metodoExportadora,
    "estado": estado,
    "observaciones": observaciones,
    "audUsuario": audUsuario,
    "cargos": cargos.map((c) => c.toJson()).toList(),
  };

  TransaccionesEntity toEntity() => TransaccionesEntity(
    idTransaccion: idTransaccion,
    numeroTransaccion: numeroTransaccion,
    idSolicitud: idSolicitud,
    idCotizacion: idCotizacion,
    idTipoTransaccion: idTipoTransaccion,
    codBanco: codBanco,
    idCanal: idCanal,
    codEmpresa: codEmpresa,
    cardCode: cardCode,
    fechaTransaccion: fechaTransaccion,
    fechaValor: fechaValor,
    montoOrigen: montoOrigen,
    idMonedaOrigen: idMonedaOrigen,
    tipoCambioAplicado: tipoCambioAplicado,
    montoConvertido: montoConvertido,
    idMonedaDestino: idMonedaDestino,
    totalCargos: totalCargos,
    totalFinal: totalFinal,
    numeroContrato: numeroContrato,
    fechaPactado: fechaPactado,
    fechaVencimiento: fechaVencimiento,
    tipoCambioForward: tipoCambioForward,
    tipoCambioReferencia: tipoCambioReferencia,
    equivalenteUsdRef: equivalenteUsdRef,
    diferenciaDeMas: diferenciaDeMas,
    porcentajeDiferencia: porcentajeDiferencia,
    nombreExportadora: nombreExportadora,
    tcNegociadoExportadora: tcNegociadoExportadora,
    comisionExportadora: comisionExportadora,
    metodoExportadora: metodoExportadora,
    estado: estado,
    observaciones: observaciones,
    audUsuario: audUsuario,
    cargos: cargos.map((c) => c.toEntity()).toList(),
  );

  factory TransaccionesModel.fromEntity(TransaccionesEntity entity) =>
      TransaccionesModel(
        idTransaccion: entity.idTransaccion,
        numeroTransaccion: entity.numeroTransaccion,
        idSolicitud: entity.idSolicitud,
        idCotizacion: entity.idCotizacion,
        idTipoTransaccion: entity.idTipoTransaccion,
        codBanco: entity.codBanco,
        idCanal: entity.idCanal,
        codEmpresa: entity.codEmpresa,
        cardCode: entity.cardCode,
        fechaTransaccion: entity.fechaTransaccion,
        fechaValor: entity.fechaValor,
        montoOrigen: entity.montoOrigen,
        idMonedaOrigen: entity.idMonedaOrigen,
        tipoCambioAplicado: entity.tipoCambioAplicado,
        montoConvertido: entity.montoConvertido,
        idMonedaDestino: entity.idMonedaDestino,
        totalCargos: entity.totalCargos,
        totalFinal: entity.totalFinal,
        numeroContrato: entity.numeroContrato,
        fechaPactado: entity.fechaPactado,
        fechaVencimiento: entity.fechaVencimiento,
        tipoCambioForward: entity.tipoCambioForward,
        tipoCambioReferencia: entity.tipoCambioReferencia,
        equivalenteUsdRef: entity.equivalenteUsdRef,
        diferenciaDeMas: entity.diferenciaDeMas,
        porcentajeDiferencia: entity.porcentajeDiferencia,
        nombreExportadora: entity.nombreExportadora,
        tcNegociadoExportadora: entity.tcNegociadoExportadora,
        comisionExportadora: entity.comisionExportadora,
        metodoExportadora: entity.metodoExportadora,
        estado: entity.estado,
        observaciones: entity.observaciones,
        audUsuario: entity.audUsuario,
      );
}
