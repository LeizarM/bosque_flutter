import 'dart:convert';
import 'package:bosque_flutter/data/models/solicitud_proveedor_model.dart';
import 'package:bosque_flutter/domain/entities/solicitud_pago_entity.dart';

SolicitudPagoModel solicitudPagoModelFromJson(String str) =>
    SolicitudPagoModel.fromJson(json.decode(str));

String solicitudPagoModelToJson(SolicitudPagoModel data) =>
    json.encode(data.toJson());

class SolicitudPagoModel {
  BigInt idSolicitud;
  int codEmpresa;
  String nombre;
  DateTime fechaSolicitud;
  double montoTotalSolicitud;
  String estado;
  int audUsuario;
  List<SolicitudProveedorModel> proveedores;

  SolicitudPagoModel({
    required this.idSolicitud,
    required this.codEmpresa,
    this.nombre = '',
    required this.fechaSolicitud,
    required this.montoTotalSolicitud,
    required this.estado,
    required this.audUsuario,
    this.proveedores = const [],
  });

  factory SolicitudPagoModel.fromJson(Map<String, dynamic> json) {
    final proveedoresJson = json["proveedores"] as List<dynamic>? ?? [];
    return SolicitudPagoModel(
      idSolicitud:
          json["idSolicitud"] != null
              ? BigInt.from(json["idSolicitud"])
              : BigInt.zero,
      codEmpresa: json["codEmpresa"] ?? 0,
      nombre: json["nombre"] ?? '',
      fechaSolicitud:
          json["fechaSolicitud"] != null
              ? DateTime.parse(json["fechaSolicitud"])
              : DateTime.now(),
      montoTotalSolicitud: json["montoTotalSolicitud"]?.toDouble() ?? 0.0,
      estado: json["estado"] ?? '',
      audUsuario: json["audUsuario"] ?? 0,
      proveedores:
          proveedoresJson
              .map(
                (p) =>
                    SolicitudProveedorModel.fromJson(p as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "idSolicitud": idSolicitud.toInt(),
    "codEmpresa": codEmpresa,
    "nombre": nombre,
    "fechaSolicitud": fechaSolicitud.toIso8601String(),
    "montoTotalSolicitud": montoTotalSolicitud,
    "estado": estado,
    "audUsuario": audUsuario,
    "proveedores": proveedores.map((p) => p.toJson()).toList(),
  };

  // Método para convertir de Model a Entity
  SolicitudPagoEntity toEntity() => SolicitudPagoEntity(
    idSolicitud: idSolicitud,
    codEmpresa: codEmpresa,
    nombre: nombre,
    fechaSolicitud: fechaSolicitud,
    montoTotalSolicitud: montoTotalSolicitud,
    estado: estado,
    audUsuario: audUsuario,
    proveedores: proveedores.map((p) => p.toEntity()).toList(),
  );

  // Método factory para convertir de Entity a Model
  factory SolicitudPagoModel.fromEntity(SolicitudPagoEntity entity) =>
      SolicitudPagoModel(
        idSolicitud: entity.idSolicitud,
        codEmpresa: entity.codEmpresa,
        nombre: entity.nombre,
        fechaSolicitud: entity.fechaSolicitud,
        montoTotalSolicitud: entity.montoTotalSolicitud,
        estado: entity.estado,
        audUsuario: entity.audUsuario,
      );
}
