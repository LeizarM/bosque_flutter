import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/domain/entities/talonario_detalle_entity.dart';

TalonarioDetalleModel talonarioDetalleModelFromJson(String str) =>
    TalonarioDetalleModel.fromJson(json.decode(str));

String talonarioDetalleModelToJson(TalonarioDetalleModel data) =>
    json.encode(data.toJson());

BigInt _big(dynamic v) =>
    v == null ? BigInt.zero : BigInt.from((v as num).toInt());
DateTime? _fecha(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

/// Formato que espera el backend en los payloads de fecha.
final DateFormat _fmtPayload = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

class TalonarioDetalleModel {
  BigInt codDetalle;
  BigInt codTalonario;
  int codEstado;
  DateTime? fechaDetalle;
  DateTime? fechaEvento;
  BigInt codSucursal;
  BigInt codEmpleado;
  String observacion;
  BigInt audUsuario;
  DateTime? audFecha;

  // ---- solo lectura ----
  String datoEstado;
  String datoSucursal;
  String datoEmpleado;
  String nroTalonario;
  String sigla;
  String datoTalonario;
  String datoFechaDetalle;
  String datoFechaEvento;
  String tipoDestinatario;
  BigInt codDestinatario;
  String datoDestinatario;

  TalonarioDetalleModel({
    required this.codDetalle,
    required this.codTalonario,
    required this.codEstado,
    this.fechaDetalle,
    this.fechaEvento,
    required this.codSucursal,
    required this.codEmpleado,
    required this.observacion,
    required this.audUsuario,
    this.audFecha,
    this.datoEstado = '',
    this.datoSucursal = '',
    this.datoEmpleado = '',
    this.nroTalonario = '',
    this.sigla = '',
    this.datoTalonario = '',
    this.datoFechaDetalle = '',
    this.datoFechaEvento = '',
    this.tipoDestinatario = '',
    BigInt? codDestinatario,
    this.datoDestinatario = '',
  }) : codDestinatario = codDestinatario ?? BigInt.zero;

  factory TalonarioDetalleModel.fromJson(Map<String, dynamic> json) =>
      TalonarioDetalleModel(
        codDetalle: _big(json["codDetalle"]),
        codTalonario: _big(json["codTalonario"]),
        codEstado: json["codEstado"] ?? 0,
        fechaDetalle: _fecha(json["fechaDetalle"]),
        fechaEvento: _fecha(json["fechaEvento"]),
        codSucursal: _big(json["codSucursal"]),
        codEmpleado: _big(json["codEmpleado"]),
        observacion: json["observacion"] ?? '',
        audUsuario: _big(json["audUsuario"]),
        audFecha: _fecha(json["audFecha"]),
        datoEstado: json["datoEstado"] ?? '',
        datoSucursal: json["datoSucursal"] ?? '',
        datoEmpleado: json["datoEmpleado"] ?? '',
        nroTalonario: json["nroTalonario"] ?? '',
        sigla: json["sigla"] ?? '',
        datoTalonario: json["datoTalonario"] ?? '',
        datoFechaDetalle: json["datoFechaDetalle"] ?? '',
        datoFechaEvento: json["datoFechaEvento"] ?? '',
        tipoDestinatario: json["tipoDestinatario"] ?? '',
        codDestinatario: _big(json["codDestinatario"]),
        datoDestinatario: json["datoDestinatario"] ?? '',
      );

  /// Solo lo que acepta el SP de ABM. fechaDetalle NO se envía: la fija el
  /// backend con GETDATE(). codEstado tampoco se puede modificar en un UPDATE,
  /// pero va igual porque el INSERT lo necesita.
  Map<String, dynamic> toJson() => {
    "codDetalle": codDetalle.toInt(),
    "codTalonario": codTalonario.toInt(),
    "codEstado": codEstado,
    "fechaEvento":
        fechaEvento == null ? null : _fmtPayload.format(fechaEvento!),
    "codSucursal": codSucursal.toInt(),
    "codEmpleado": codEmpleado.toInt(),
    "observacion": observacion,
    "audUsuario": audUsuario.toInt(),
  };

  TalonarioDetalleEntity toEntity() => TalonarioDetalleEntity(
    codDetalle: codDetalle,
    codTalonario: codTalonario,
    codEstado: codEstado,
    fechaDetalle: fechaDetalle,
    fechaEvento: fechaEvento,
    codSucursal: codSucursal,
    codEmpleado: codEmpleado,
    observacion: observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    datoEstado: datoEstado,
    datoSucursal: datoSucursal,
    datoEmpleado: datoEmpleado,
    nroTalonario: nroTalonario,
    sigla: sigla,
    datoTalonario: datoTalonario,
    datoFechaDetalle: datoFechaDetalle,
    datoFechaEvento: datoFechaEvento,
    tipoDestinatario: tipoDestinatario,
    codDestinatario: codDestinatario,
    datoDestinatario: datoDestinatario,
  );

  factory TalonarioDetalleModel.fromEntity(TalonarioDetalleEntity e) =>
      TalonarioDetalleModel(
        codDetalle: e.codDetalle,
        codTalonario: e.codTalonario,
        codEstado: e.codEstado,
        fechaDetalle: e.fechaDetalle,
        fechaEvento: e.fechaEvento,
        codSucursal: e.codSucursal,
        codEmpleado: e.codEmpleado,
        observacion: e.observacion,
        audUsuario: e.audUsuario,
        audFecha: e.audFecha,
        datoEstado: e.datoEstado,
        datoSucursal: e.datoSucursal,
        datoEmpleado: e.datoEmpleado,
        nroTalonario: e.nroTalonario,
        sigla: e.sigla,
        datoTalonario: e.datoTalonario,
        datoFechaDetalle: e.datoFechaDetalle,
        datoFechaEvento: e.datoFechaEvento,
        tipoDestinatario: e.tipoDestinatario,
        codDestinatario: e.codDestinatario,
        datoDestinatario: e.datoDestinatario,
      );
}
