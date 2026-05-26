// To parse this JSON data, do
//
//     final anticipoModel = anticipoModelFromJson(jsonString);

import 'dart:convert';
import 'package:bosque_flutter/domain/entities/multa_entity.dart';

// Funciones de ayuda para conversión
MultaResponse multaResponseFromJson(String str) =>
    MultaResponse.fromJson(json.decode(str));
String multaResponseToJson(MultaResponse data) => json.encode(data.toJson());

class MultaResponse {
  String message;
  List<MultaModel> data;
  int status;
  int? idGenerado;

  MultaResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory MultaResponse.fromJson(Map<String, dynamic> json) {
    List<MultaModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<MultaModel>.from(
          (json["data"] as List).map((x) => MultaModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return MultaResponse(
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

class MultaModel {
  int codMulta;
  int codEmpleado;
  int? anio;
  int? mes;
  double? diasTrabajados;
  double? diasMulta;
  double monto;
  // String estado;
  int audUsuarioI;
  int? fila;
  int? pagina;
  int? tamanoPagina;
  int? totalPaginas;
  String? search;
  int? totalRegistros;
  String nombreCompleto;
  String seguroNombre;
  double haberBasico;
  int? codEmpresa;

  MultaModel({
    required this.codMulta,
    required this.codEmpleado,
    required this.anio,
    required this.mes,
    required this.diasTrabajados,
    required this.diasMulta,
    required this.monto,
    // required this.estado,
    required this.audUsuarioI,
    this.fila,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.search,
    this.totalRegistros,
    required this.nombreCompleto,
    required this.seguroNombre,
    required this.haberBasico,
    this.codEmpresa,
  });

  factory MultaModel.fromJson(Map<String, dynamic> json) => MultaModel(
    codMulta: json["codMulta"] ?? 0,
    codEmpleado: json["codEmpleado"] ?? 0,
    anio: json["anio"] ?? 0,
    mes: json["mes"] ?? 0,
    diasTrabajados: json["diasTrabajados"]?.toDouble() ?? 0.0,
    diasMulta: json["diasMulta"]?.toDouble() ?? 0.0,
    monto: json["monto"]?.toDouble() ?? 0.0,
    //estado: json["estado"] ?? '',
    audUsuarioI: json["audUsuarioI"] ?? json["audUsuario"] ?? 0,
    fila: json["fila"] ?? 0,
    pagina: json["pagina"] ?? 0,
    tamanoPagina: json["tamanoPagina"] ?? 0,
    totalPaginas: json["totalPaginas"] ?? 0,
    search: json["search"] ?? '',
    totalRegistros: json["totalRegistros"] ?? 0,
    nombreCompleto: json["nombreCompleto"] ?? '',
    seguroNombre: json["seguroNombre"] ?? '',
    haberBasico: json["haberBasico"]?.toDouble() ?? 0.0,
    codEmpresa: json["codEmpresa"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "codMulta": codMulta,
    "codEmpleado": codEmpleado,
    "anio": anio,
    "mes": mes,
    "diasTrabajados": diasTrabajados,
    "diasMulta": diasMulta,
    "monto": monto,
    //"estado": estado,
    "audUsuarioI": audUsuarioI,
    "fila": fila,
    "pagina": pagina,
    "tamanoPagina": tamanoPagina,
    "totalPaginas": totalPaginas,
    "search": search,
    "totalRegistros": totalRegistros,
    "nombreCompleto": nombreCompleto,
    "seguroNombre": seguroNombre,
    "haberBasico": haberBasico,
    "codEmpresa": codEmpresa,
  };
  MultaEntity toEntity() => MultaEntity(
    codMulta: codMulta,
    codEmpleado: codEmpleado,
    anio: anio,
    mes: mes,
    diasTrabajados: diasTrabajados,
    diasMulta: diasMulta,
    monto: monto,
    // estado: estado,
    audUsuarioI: audUsuarioI,
    fila: fila,
    pagina: pagina,
    tamanoPagina: tamanoPagina,
    totalPaginas: totalPaginas,
    search: search,
    totalRegistros: totalRegistros,
    nombreCompleto: nombreCompleto,
    seguroNombre: seguroNombre,
    haberBasico: haberBasico,
    codEmpresa: codEmpresa,
  );
  factory MultaModel.fromEntity(MultaEntity entity) => MultaModel(
    codMulta: entity.codMulta,
    codEmpleado: entity.codEmpleado,
    anio: entity.anio,
    mes: entity.mes,
    diasTrabajados: entity.diasTrabajados,
    diasMulta: entity.diasMulta,
    monto: entity.monto,
    // estado: entity.estado,
    audUsuarioI: entity.audUsuarioI,
    fila: entity.fila,
    pagina: entity.pagina,
    tamanoPagina: entity.tamanoPagina,
    totalPaginas: entity.totalPaginas,
    search: entity.search,
    totalRegistros: entity.totalRegistros,
    nombreCompleto: entity.nombreCompleto,
    seguroNombre: entity.seguroNombre,
    haberBasico: entity.haberBasico,
    codEmpresa: entity.codEmpresa,
  );
}
