import 'dart:convert';
import 'package:bosque_flutter/domain/entities/log_estados_entity.dart';

LogEstadosModel logEstadosModelFromJson(String str) =>
    LogEstadosModel.fromJson(json.decode(str));

String logEstadosModelToJson(LogEstadosModel data) =>
    json.encode(data.toJson());

class LogEstadosModel {
  BigInt idLog;
  BigInt idSolicitud;
  BigInt idCotizacion;
  BigInt idTransaccion;
  String tipoEntidad;
  String idEntidad;
  String estadoAnterior;
  String estadoNuevo;
  String observaciones;
  DateTime fechaCreacion;
  int audUsuario;
  String nombreUsuario;

  LogEstadosModel({
    required this.idLog,
    required this.idSolicitud,
    required this.idCotizacion,
    required this.idTransaccion,
    this.tipoEntidad = '',
    this.idEntidad = '',
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.observaciones,
    required this.fechaCreacion,
    required this.audUsuario,
    this.nombreUsuario = '',
  });

  factory LogEstadosModel.fromJson(Map<String, dynamic> json) =>
      LogEstadosModel(
        idLog: json["idLog"] != null ? BigInt.from(json["idLog"]) : BigInt.zero,
        idSolicitud:
            json["idSolicitud"] != null
                ? BigInt.from(json["idSolicitud"])
                : BigInt.zero,
        idCotizacion:
            json["idCotizacion"] != null
                ? BigInt.from(json["idCotizacion"])
                : BigInt.zero,
        idTransaccion:
            json["idTransaccion"] != null
                ? BigInt.from(json["idTransaccion"])
                : BigInt.zero,
        tipoEntidad: json["tipoEntidad"]?.toString() ?? '',
        idEntidad: json["idEntidad"]?.toString() ?? '',
        estadoAnterior: json["estadoAnterior"] ?? '',
        estadoNuevo: json["estadoNuevo"] ?? '',
        observaciones: json["observaciones"] ?? '',
        fechaCreacion:
            json["fechaCreacion"] != null
                ? DateTime.tryParse(json["fechaCreacion"].toString()) ??
                    (json["audFecha"] != null
                        ? DateTime.tryParse(json["audFecha"].toString()) ??
                            DateTime.now()
                        : DateTime.now())
                : (json["audFecha"] != null
                    ? DateTime.tryParse(json["audFecha"].toString()) ??
                        DateTime.now()
                    : DateTime.now()),
        audUsuario: json["audUsuario"] ?? 0,
        nombreUsuario: json["nombreUsuario"]?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    "idLog": idLog.toInt(),
    "idSolicitud": idSolicitud.toInt(),
    "idCotizacion": idCotizacion.toInt(),
    "idTransaccion": idTransaccion.toInt(),
    "tipoEntidad": tipoEntidad,
    "idEntidad": idEntidad,
    "estadoAnterior": estadoAnterior,
    "estadoNuevo": estadoNuevo,
    "observaciones": observaciones,
    "fechaCreacion": fechaCreacion.toIso8601String(),
    "audUsuario": audUsuario,
    "nombreUsuario": nombreUsuario,
  };

  LogEstadosEntity toEntity() => LogEstadosEntity(
    idLog: idLog,
    idSolicitud: idSolicitud,
    idCotizacion: idCotizacion,
    idTransaccion: idTransaccion,
    tipoEntidad: tipoEntidad,
    idEntidad: idEntidad,
    estadoAnterior: estadoAnterior,
    estadoNuevo: estadoNuevo,
    observaciones: observaciones,
    fechaCreacion: fechaCreacion,
    audUsuario: audUsuario,
    nombreUsuario: nombreUsuario,
  );

  factory LogEstadosModel.fromEntity(LogEstadosEntity entity) =>
      LogEstadosModel(
        idLog: entity.idLog,
        idSolicitud: entity.idSolicitud,
        idCotizacion: entity.idCotizacion,
        idTransaccion: entity.idTransaccion,
        tipoEntidad: entity.tipoEntidad,
        idEntidad: entity.idEntidad,
        estadoAnterior: entity.estadoAnterior,
        estadoNuevo: entity.estadoNuevo,
        observaciones: entity.observaciones,
        fechaCreacion: entity.fechaCreacion,
        audUsuario: entity.audUsuario,
        nombreUsuario: entity.nombreUsuario,
      );
}
