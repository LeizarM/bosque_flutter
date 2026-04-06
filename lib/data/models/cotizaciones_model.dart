import 'dart:convert';
import 'package:bosque_flutter/data/models/cargo_pago_model.dart';
import 'package:bosque_flutter/domain/entities/cotizaciones_entity.dart';

CotizacionesModel cotizacionesModelFromJson(String str) =>
    CotizacionesModel.fromJson(json.decode(str));

String cotizacionesModelToJson(CotizacionesModel data) =>
    json.encode(data.toJson());

class CotizacionesModel {
  BigInt idCotizacion;
  BigInt idSolicitud;
  DateTime fechaCotizacion;
  double montoCompra;
  int idMoneda;
  int nroGiros;
  int codBanco;
  double tipoCambioOfrecido;
  double montoConvertido;
  double totalBolivianos;
  int esGanadora;
  String estado;
  String observaciones;
  int audUsuario;
  List<CargoPagoModel> cargos;
  DateTime fechaInicio;
  DateTime fechaFin;

  CotizacionesModel({
    required this.idCotizacion,
    required this.idSolicitud,
    required this.fechaCotizacion,
    required this.montoCompra,
    required this.idMoneda,
    required this.nroGiros,
    required this.codBanco,
    required this.tipoCambioOfrecido,
    required this.montoConvertido,
    required this.totalBolivianos,
    required this.esGanadora,
    required this.estado,
    required this.observaciones,
    required this.audUsuario,
    this.cargos = const [],
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory CotizacionesModel.fromJson(Map<String, dynamic> json) {
    final cargosJson = json["cargos"] as List<dynamic>? ?? [];
    return CotizacionesModel(
      idCotizacion:
          json["idCotizacion"] != null
              ? BigInt.from(json["idCotizacion"])
              : BigInt.zero,
      idSolicitud:
          json["idSolicitud"] != null
              ? BigInt.from(json["idSolicitud"])
              : BigInt.zero,
      fechaCotizacion:
          json["fechaCotizacion"] != null
              ? DateTime.parse(json["fechaCotizacion"])
              : DateTime.now(),
      montoCompra: json["montoCompra"]?.toDouble() ?? 0.0,
      idMoneda: json["idMoneda"] ?? 0,
      nroGiros: json["nroGiros"] ?? 0,
      codBanco: json["codBanco"] ?? 0,
      tipoCambioOfrecido: json["tipoCambioOfrecido"]?.toDouble() ?? 0.0,
      montoConvertido: json["montoConvertido"]?.toDouble() ?? 0.0,
      totalBolivianos: json["totalBolivianos"]?.toDouble() ?? 0.0,
      esGanadora: json["esGanadora"] ?? 0,
      estado: json["estado"] ?? '',
      observaciones: json["observaciones"] ?? '',
      audUsuario: json["audUsuario"] ?? 0,
      cargos:
          cargosJson
              .map((c) => CargoPagoModel.fromJson(c as Map<String, dynamic>))
              .toList(),
      fechaInicio:
          json["fechaInicio"] != null
              ? DateTime.parse(json["fechaInicio"])
              : DateTime.now(),
      fechaFin:
          json["fechaFin"] != null
              ? DateTime.parse(json["fechaFin"])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    "idCotizacion": idCotizacion.toInt(),
    "idSolicitud": idSolicitud.toInt(),
    "fechaCotizacion": fechaCotizacion
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "montoCompra": montoCompra,
    "idMoneda": idMoneda,
    "nroGiros": nroGiros,
    "codBanco": codBanco,
    "tipoCambioOfrecido": tipoCambioOfrecido,
    "montoConvertido": montoConvertido,
    "totalBolivianos": totalBolivianos,
    "esGanadora": esGanadora,
    "estado": estado,
    "observaciones": observaciones,
    "audUsuario": audUsuario,
    "cargos": cargos.map((c) => c.toJson()).toList(),
    "fechaInicio": fechaInicio
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
    "fechaFin": fechaFin
        .toIso8601String()
        .substring(0, 19)
        .replaceAll('T', ' '),
  };

  CotizacionesEntity toEntity() => CotizacionesEntity(
    idCotizacion: idCotizacion,
    idSolicitud: idSolicitud,
    fechaCotizacion: fechaCotizacion,
    montoCompra: montoCompra,
    idMoneda: idMoneda,
    nroGiros: nroGiros,
    codBanco: codBanco,
    tipoCambioOfrecido: tipoCambioOfrecido,
    montoConvertido: montoConvertido,
    totalBolivianos: totalBolivianos,
    esGanadora: esGanadora,
    estado: estado,
    observaciones: observaciones,
    audUsuario: audUsuario,
    cargos: cargos.map((c) => c.toEntity()).toList(),
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
  );

  factory CotizacionesModel.fromEntity(CotizacionesEntity entity) =>
      CotizacionesModel(
        idCotizacion: entity.idCotizacion,
        idSolicitud: entity.idSolicitud,
        fechaCotizacion: entity.fechaCotizacion,
        montoCompra: entity.montoCompra,
        idMoneda: entity.idMoneda,
        nroGiros: entity.nroGiros,
        codBanco: entity.codBanco,
        tipoCambioOfrecido: entity.tipoCambioOfrecido,
        montoConvertido: entity.montoConvertido,
        totalBolivianos: entity.totalBolivianos,
        esGanadora: entity.esGanadora,
        estado: entity.estado,
        observaciones: entity.observaciones,
        audUsuario: entity.audUsuario,
        cargos: entity.cargos.map((c) => CargoPagoModel.fromEntity(c)).toList(),
        fechaInicio: entity.fechaInicio,
        fechaFin: entity.fechaFin,
      );
}
