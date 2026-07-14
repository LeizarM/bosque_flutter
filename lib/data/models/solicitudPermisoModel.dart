import 'dart:convert';
import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';

SolicitudPermisoResponse solicitudPermisoResponseFromJson(String str) =>
    SolicitudPermisoResponse.fromJson(json.decode(str));
String solicitudPermisoResponseToJson(SolicitudPermisoResponse data) =>
    json.encode(data.toJson());

class SolicitudPermisoResponse {
  String message;
  List<SolicitudPermisoModel> data;
  int status;
  int? idGenerado;

  SolicitudPermisoResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory SolicitudPermisoResponse.fromJson(Map<String, dynamic> json) {
    List<SolicitudPermisoModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<SolicitudPermisoModel>.from(
          (json["data"] as List).map((x) => SolicitudPermisoModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return SolicitudPermisoResponse(
      message: json["message"] ?? '',
      data: listaData,
      status: json["status"] ?? 0,
      idGenerado: json["idGenerado"] ?? idGen,
    );
  }

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "status": status,
    "idGenerado": idGenerado,
  };
}

class SolicitudPermisoModel {
  final int? codSolicitud;
  final int codEmpleado;
  final int codRelEmplEmpr;
  final String tipoPermiso;
  final DateTime desde;
  final DateTime hasta;
  final String motivo;
  final double cantidadDias;
  final int estado;
  final int audUsuarioI;
  // ── Auxiliares del listado de pendientes ──
  final String? nombreEmpleado;
  final String? cargoEmpleado;
  final DateTime? fechaSolicitud;
  final String? pasoActual;
  final int? codPermiso;
  final String? autorizador;

  // ── Auxiliares para previsualizar saldo (acción 'C') ──────────
  final double? diasSolicitados;
  final String? diasSolicitadosTxt;
  final double? saldoRestante;
  final String? saldoRestanteTxt;
  final double? saldoActualBase;
  final String? saldoActualBaseTxt;
  final double? diasDisponibles;
  final String? diasDisponiblesTxt;
  final String? motivoRechazo;
  final String? fechasTxt;

  SolicitudPermisoModel({
    this.codSolicitud,
    required this.codEmpleado,
    required this.codRelEmplEmpr,
    required this.tipoPermiso,
    required this.desde,
    required this.hasta,
    required this.motivo,
    required this.cantidadDias,
    required this.estado,
    required this.audUsuarioI,
    this.nombreEmpleado,
    this.cargoEmpleado,
    this.fechaSolicitud,
    this.pasoActual,
    this.codPermiso,
    this.autorizador,
    this.diasDisponibles,
    this.diasDisponiblesTxt,
    this.motivoRechazo,
    this.fechasTxt,
    this.diasSolicitados,
    this.diasSolicitadosTxt,
    this.saldoRestante,
    this.saldoRestanteTxt,
    this.saldoActualBase,
    this.saldoActualBaseTxt,
  });

  factory SolicitudPermisoModel.fromJson(Map<String, dynamic> json) =>
      SolicitudPermisoModel(
        codSolicitud: json["codSolicitud"] ?? 0,
        codEmpleado: json["codEmpleado"] ?? 0,
        codRelEmplEmpr: json["codRelEmplEmpr"] ?? 0,
        tipoPermiso: json["tipoPermiso"] ?? '',
        desde:
            json["desde"] != null
                ? DateTime.parse(json["desde"])
                : (json["fechaDesde"] != null
                    ? DateTime.parse(json["fechaDesde"])
                    : (json["fechaInicio"] != null
                        ? DateTime.parse(json["fechaInicio"])
                        : DateTime.now())),
        hasta:
            json["hasta"] != null
                ? DateTime.parse(json["hasta"])
                : (json["fechaHasta"] != null
                    ? DateTime.parse(json["fechaHasta"])
                    : (json["fechaFin"] != null
                        ? DateTime.parse(json["fechaFin"])
                        : DateTime.now())),
        motivo: json["motivo"] ?? '',
        cantidadDias: json["cantidadDias"]?.toDouble() ?? 0.0,
        estado: json["estado"] ?? 0,
        audUsuarioI: json["audUsuarioI"] ?? json["audUsuario"] ?? 0,
        // auxiliares — null si no vienen en el JSON
        nombreEmpleado: json['nombreEmpleado'],
        cargoEmpleado: json['cargoEmpleado'],
        fechaSolicitud:
            json['fechaSolicitud'] != null
                ? DateTime.parse(json['fechaSolicitud'])
                : null,
        pasoActual: json['pasoActual'],
        codPermiso: json['codPermiso'],
        autorizador: json['autorizador'],
        diasDisponibles: json['diasDisponibles']?.toDouble(),
        diasDisponiblesTxt: json['diasDisponiblesTxt'],
        motivoRechazo: json['motivoRechazo'],
        fechasTxt: json['fechasTxt'],
        diasSolicitados: json['diasSolicitados']?.toDouble(),
        diasSolicitadosTxt: json['diasSolicitadosTxt'],
        saldoRestante: json['saldoRestante']?.toDouble(),
        saldoRestanteTxt: json['saldoRestanteTxt'],
        saldoActualBase: json['saldoActualBase']?.toDouble(),
        saldoActualBaseTxt: json['saldoActualBaseTxt'],
      );

  Map<String, dynamic> toJson() => {
    "codSolicitud": codSolicitud,
    "codEmpleado": codEmpleado,
    "codRelEmplEmpr": codRelEmplEmpr,
    "tipoPermiso": tipoPermiso,
    "desde": desde.toIso8601String(),
    "hasta": hasta.toIso8601String(),
    "motivo": motivo,
    "cantidadDias": cantidadDias,
    "estado": estado,
    "audUsuarioI": audUsuarioI,
    "codPermiso": codPermiso,
    "autorizador": autorizador,
    "diasDisponibles": diasDisponibles,
    "diasDisponiblesTxt": diasDisponiblesTxt,
    "motivoRechazo": motivoRechazo,
    "fechasTxt": fechasTxt,
    "diasSolicitados": diasSolicitados,
    "diasSolicitadosTxt": diasSolicitadosTxt,
    "saldoRestante": saldoRestante,
    "saldoRestanteTxt": saldoRestanteTxt,
    "saldoActualBase": saldoActualBase,
    "saldoActualBaseTxt": saldoActualBaseTxt,
  };
  SolicitudPermisoEntity toEntity() => SolicitudPermisoEntity(
    codSolicitud: codSolicitud,
    codEmpleado: codEmpleado,
    codRelEmplEmpr: codRelEmplEmpr,
    tipoPermiso: tipoPermiso,
    desde: desde,
    hasta: hasta,
    motivo: motivo,
    cantidadDias: cantidadDias,
    estado: estado,
    audUsuarioI: audUsuarioI,
    nombreEmpleado: nombreEmpleado,
    cargoEmpleado: cargoEmpleado,
    fechaSolicitud: fechaSolicitud,
    pasoActual: pasoActual,
    codPermiso: codPermiso,
    autorizador: autorizador,
    diasDisponibles: diasDisponibles,
    diasDisponiblesTxt: diasDisponiblesTxt,
    motivoRechazo: motivoRechazo,
    fechasTxt: fechasTxt,
    diasSolicitados: diasSolicitados,
    diasSolicitadosTxt: diasSolicitadosTxt,
    saldoRestante: saldoRestante,
    saldoRestanteTxt: saldoRestanteTxt,
    saldoActualBase: saldoActualBase,
    saldoActualBaseTxt: saldoActualBaseTxt,
  );
  factory SolicitudPermisoModel.fromEntity(SolicitudPermisoEntity entity) =>
      SolicitudPermisoModel(
        codSolicitud: entity.codSolicitud,
        codEmpleado: entity.codEmpleado,
        codRelEmplEmpr: entity.codRelEmplEmpr,
        tipoPermiso: entity.tipoPermiso,
        desde: entity.desde,
        hasta: entity.hasta,
        motivo: entity.motivo,
        cantidadDias: entity.cantidadDias,
        estado: entity.estado,
        audUsuarioI: entity.audUsuarioI,
        nombreEmpleado: entity.nombreEmpleado,
        cargoEmpleado: entity.cargoEmpleado,
        fechaSolicitud: entity.fechaSolicitud,
        pasoActual: entity.pasoActual,
        codPermiso: entity.codPermiso,
        autorizador: entity.autorizador,
        diasDisponibles: entity.diasDisponibles,
        diasDisponiblesTxt: entity.diasDisponiblesTxt,
        motivoRechazo: entity.motivoRechazo,
        fechasTxt: entity.fechasTxt,
        diasSolicitados: entity.diasSolicitados,
        diasSolicitadosTxt: entity.diasSolicitadosTxt,
        saldoRestante: entity.saldoRestante,
        saldoRestanteTxt: entity.saldoRestanteTxt,
        saldoActualBase: entity.saldoActualBase,
        saldoActualBaseTxt: entity.saldoActualBaseTxt,
      );
}
