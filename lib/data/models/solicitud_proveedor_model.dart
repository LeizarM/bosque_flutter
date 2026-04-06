import 'dart:convert';
import 'package:bosque_flutter/data/models/detalle_solicitud_model.dart';
import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';

SolicitudProveedorModel solicitudProveedorModelFromJson(String str) =>
    SolicitudProveedorModel.fromJson(json.decode(str));

String solicitudProveedorModelToJson(SolicitudProveedorModel data) =>
    json.encode(data.toJson());

class SolicitudProveedorModel {
  BigInt idSolicitudProveedor;
  BigInt idSolicitud;
  String cardCode;
  String cardName;
  double totalFacturasUsd;
  double totalAmortizadoUsd;
  double totalAPagarUsd;
  String obs;
  int audUsuario;

  int codEmpresa;
  List<DetalleSolicitudModel> detalles;

  SolicitudProveedorModel({
    required this.idSolicitudProveedor,
    required this.idSolicitud,
    required this.cardCode,
    required this.cardName,
    required this.totalFacturasUsd,
    required this.totalAmortizadoUsd,
    required this.totalAPagarUsd,
    required this.obs,
    required this.audUsuario,
    required this.codEmpresa,
    this.detalles = const [],
  });

  factory SolicitudProveedorModel.fromJson(Map<String, dynamic> json) {
    final detallesJson = json["detalles"] as List<dynamic>? ?? [];
    return SolicitudProveedorModel(
      idSolicitudProveedor:
          json["idSolicitudProveedor"] != null
              ? BigInt.from(json["idSolicitudProveedor"])
              : BigInt.zero,
      idSolicitud:
          json["idSolicitud"] != null
              ? BigInt.from(json["idSolicitud"])
              : BigInt.zero,
      cardCode: json["cardCode"] ?? '',
      cardName: json["cardName"] ?? '',
      totalFacturasUsd: json["totalFacturasUsd"]?.toDouble() ?? 0.0,
      totalAmortizadoUsd: json["totalAmortizadoUsd"]?.toDouble() ?? 0.0,
      totalAPagarUsd: json["totalAPagarUsd"]?.toDouble() ?? 0.0,
      obs: json["obs"] ?? '',
      audUsuario: json["audUsuario"] ?? 0,
      codEmpresa: json["codEmpresa"] ?? 0,
      detalles:
          detallesJson
              .map(
                (d) =>
                    DetalleSolicitudModel.fromJson(d as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "idSolicitudProveedor": idSolicitudProveedor.toInt(),
    "idSolicitud": idSolicitud.toInt(),
    "cardCode": cardCode,
    "cardName": cardName,
    "totalFacturasUsd": totalFacturasUsd,
    "totalAmortizadoUsd": totalAmortizadoUsd,
    "totalAPagarUsd": totalAPagarUsd,
    "obs": obs,
    "audUsuario": audUsuario,
    "codEmpresa": codEmpresa,
    "detalles": detalles.map((d) => d.toJson()).toList(),
  };

  // Método para convertir de Model a Entity
  SolicitudProveedorEntity toEntity() => SolicitudProveedorEntity(
    idSolicitudProveedor: idSolicitudProveedor,
    idSolicitud: idSolicitud,
    cardCode: cardCode,
    cardName: cardName,
    totalFacturasUsd: totalFacturasUsd,
    totalAmortizadoUsd: totalAmortizadoUsd,
    totalAPagarUsd: totalAPagarUsd,
    obs: obs,
    audUsuario: audUsuario,
    codEmpresa: codEmpresa,
    detalles: detalles.map((d) => d.toEntity()).toList(),
  );

  // Método factory para convertir de Entity a Model
  factory SolicitudProveedorModel.fromEntity(SolicitudProveedorEntity entity) =>
      SolicitudProveedorModel(
        idSolicitudProveedor: entity.idSolicitudProveedor,
        idSolicitud: entity.idSolicitud,
        cardCode: entity.cardCode,
        cardName: entity.cardName,
        totalFacturasUsd: entity.totalFacturasUsd,
        totalAmortizadoUsd: entity.totalAmortizadoUsd,
        totalAPagarUsd: entity.totalAPagarUsd,
        obs: entity.obs,
        audUsuario: entity.audUsuario,
        codEmpresa: entity.codEmpresa,
      );
}
