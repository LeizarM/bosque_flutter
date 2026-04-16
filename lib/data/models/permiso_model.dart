import 'dart:convert';

import 'package:bosque_flutter/domain/entities/permiso_entity.dart';

// Funciones de ayuda para conversión
PermisoResponse permisoResponseFromJson(String str) =>
    PermisoResponse.fromJson(json.decode(str));
String permisoResponseToJson(PermisoResponse data) =>
    json.encode(data.toJson());

class PermisoResponse {
  String message;
  List<PermisoModel> data;
  int status;
  int? idGenerado;

  PermisoResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory PermisoResponse.fromJson(Map<String, dynamic> json) {
    List<PermisoModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<PermisoModel>.from(
          (json["data"] as List).map((x) => PermisoModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return PermisoResponse(
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

class PermisoModel {
  int codPermiso;
  int codEmpleado;
  int? codUsuarioAutorizador;
  String tipoPermiso;
  DateTime? desde;
  DateTime? hasta;
  String motivo;
  double cantidadDias;
  int codRelEmplEmpr;
  int audUsuarioI;
  DateTime? audFechaI;

  // Campos Auxiliares que vienen del SP (Acción H1)
  double cantidadDiasTotal;
  double cantidadDiasAsig;
  double cantidadDiasAbon;
  DateTime? fecRango;

  PermisoModel({
    required this.codPermiso,
    required this.codEmpleado,
    this.codUsuarioAutorizador,
    required this.tipoPermiso,
    this.desde,
    this.hasta,
    required this.motivo,
    required this.cantidadDias,
    required this.codRelEmplEmpr,
    required this.audUsuarioI,
    this.audFechaI,
    required this.cantidadDiasTotal,
    required this.cantidadDiasAsig,
    required this.cantidadDiasAbon,
    this.fecRango,
  });

  factory PermisoModel.fromJson(Map<String, dynamic> json) => PermisoModel(
    codPermiso: json["codPermiso"] ?? 0,
    codEmpleado: json["codEmpleado"] ?? 0,
    codUsuarioAutorizador: json["codUsuarioAutorizador"],
    tipoPermiso: json["tipoPermiso"] ?? '',
    desde: json["desde"] != null ? DateTime.parse(json["desde"]) : null,
    hasta: json["hasta"] != null ? DateTime.parse(json["hasta"]) : null,
    motivo: json["motivo"] ?? '',
    cantidadDias: (json["cantidadDias"] as num?)?.toDouble() ?? 0.0,
    codRelEmplEmpr: json["codRelEmplEmpr"] ?? 0,
    audUsuarioI: json["audUsuarioI"] ?? 0,
    audFechaI:
        json["audFechaI"] != null ? DateTime.parse(json["audFechaI"]) : null,
    // Mapeo de auxiliares (Usando num para evitar errores entre int/double de SQL)
    cantidadDiasTotal: (json["cantidadDiasTotal"] as num?)?.toDouble() ?? 0.0,
    cantidadDiasAsig: (json["cantidadDiasAsig"] as num?)?.toDouble() ?? 0.0,
    cantidadDiasAbon: (json["cantidadDiasAbon"] as num?)?.toDouble() ?? 0.0,
    fecRango:
        json["fecRango"] != null ? DateTime.parse(json["fecRango"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "codPermiso": codPermiso,
    "codEmpleado": codEmpleado,
    "codUsuarioAutorizador": codUsuarioAutorizador,
    "tipoPermiso": tipoPermiso,
    "desde": desde?.toIso8601String(),
    "hasta": hasta?.toIso8601String(),
    "motivo": motivo,
    "cantidadDias": cantidadDias,
    "codRelEmplEmpr": codRelEmplEmpr,
    "audUsuarioI": audUsuarioI,
    "audFechaI": audFechaI?.toIso8601String(),
    "cantidadDiasTotal": cantidadDiasTotal,
    "cantidadDiasAsig": cantidadDiasAsig,
    "cantidadDiasAbon": cantidadDiasAbon,
    "fecRango": fecRango?.toIso8601String(),
  };

  PermisoEntity toEntity() => PermisoEntity(
    codPermiso: codPermiso,
    codEmpleado: codEmpleado,
    tipoPermiso: tipoPermiso,
    desde: desde,
    hasta: hasta,
    motivo: motivo,
    cantidadDias: cantidadDias,
    cantidadDiasTotal: cantidadDiasTotal,
    codRelEmplEmpr: codRelEmplEmpr,
    audUsuarioI: audUsuarioI,
    audFechaI: audFechaI,
    cantidadDiasAsig: cantidadDiasAsig,
    cantidadDiasAbon: cantidadDiasAbon,
    fecRango: fecRango,
  );
  factory PermisoModel.fromEntity(PermisoEntity entity) => PermisoModel(
    codPermiso: entity.codPermiso,
    codEmpleado: entity.codEmpleado,
    tipoPermiso: entity.tipoPermiso,
    desde: entity.desde,
    hasta: entity.hasta,
    motivo: entity.motivo,
    cantidadDias: entity.cantidadDias,
    cantidadDiasTotal: entity.cantidadDiasTotal,
    codRelEmplEmpr: entity.codRelEmplEmpr,
    audUsuarioI: entity.audUsuarioI,
    audFechaI: entity.audFechaI,
    cantidadDiasAsig: entity.cantidadDiasAsig,
    cantidadDiasAbon: entity.cantidadDiasAbon,
    fecRango: entity.fecRango,
  );
}
