import 'dart:convert';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';

SolicitudPagoModel solicitudPagoModelFromJson(String str) =>
    SolicitudPagoModel.fromJson(json.decode(str));

String solicitudPagoModelToJson(SolicitudPagoModel data) =>
    json.encode(data.toJson());

class SolicitudPagoModel {
  BigInt idSolicitud;
  int codEmpresa;
  DateTime fechaSolicitud;
  double montoTotalSolicitud;
  String estado;
  int audUsuario;

  SolicitudPagoModel({
    required this.idSolicitud,
    required this.codEmpresa,
    required this.fechaSolicitud,
    required this.montoTotalSolicitud,
    required this.estado,
    required this.audUsuario,
  });

  factory SolicitudPagoModel.fromJson(Map<String, dynamic> json) =>
      SolicitudPagoModel(
        idSolicitud:
            json["idSolicitud"] != null
                ? BigInt.from(json["idSolicitud"])
                : BigInt.zero,
        codEmpresa: json["codEmpresa"] ?? 0,
        fechaSolicitud:
            json["fechaSolicitud"] != null
                ? DateTime.parse(json["fechaSolicitud"])
                : DateTime.now(),
        montoTotalSolicitud: json["montoTotalSolicitud"]?.toDouble() ?? 0.0,
        estado: json["estado"] ?? '',
        audUsuario: json["audUsuario"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "idSolicitud": idSolicitud.toInt(),
    "codEmpresa": codEmpresa,
    "fechaSolicitud": fechaSolicitud.toIso8601String(),
    "montoTotalSolicitud": montoTotalSolicitud,
    "estado": estado,
    "audUsuario": audUsuario,
  };

  // Método para convertir de Model a Entity
  SolicitudPagoEntity toEntity() => SolicitudPagoEntity(
    idSolicitud: idSolicitud,
    codEmpresa: codEmpresa,
    fechaSolicitud: fechaSolicitud,
    montoTotalSolicitud: montoTotalSolicitud,
    estado: estado,
    audUsuario: audUsuario,
  );

  // Método factory para convertir de Entity a Model
  factory SolicitudPagoModel.fromEntity(SolicitudPagoEntity entity) =>
      SolicitudPagoModel(
        idSolicitud: entity.idSolicitud,
        codEmpresa: entity.codEmpresa,
        fechaSolicitud: entity.fechaSolicitud,
        montoTotalSolicitud: entity.montoTotalSolicitud,
        estado: entity.estado,
        audUsuario: entity.audUsuario,
      );
}
