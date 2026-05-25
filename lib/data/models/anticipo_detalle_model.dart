// To parse this JSON data, do
//
//     final anticipoDetalleModel = anticipoDetalleModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/anticipo_detalle_entity.dart';

// Funciones de ayuda para conversión
AnticipoDetalleResponse anticipoResponseFromJson(String str) =>
    AnticipoDetalleResponse.fromJson(json.decode(str));
String anticipoResponseToJson(AnticipoDetalleResponse data) =>
    json.encode(data.toJson());

class AnticipoDetalleResponse {
  String message;
  List<AnticipoDetalleModel> data;
  int status;
  int? idGenerado;

  AnticipoDetalleResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory AnticipoDetalleResponse.fromJson(Map<String, dynamic> json) {
    List<AnticipoDetalleModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<AnticipoDetalleModel>.from(
          (json["data"] as List).map((x) => AnticipoDetalleModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return AnticipoDetalleResponse(
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

class AnticipoDetalleModel {
  int codAntDetalle;
  int codAnticipo;
  int codEmpleado;
  String nombreCompleto;
  double monto;
  int codAutorizacion;
  String estadoAnticipo;
  DateTime fechaAnticipo;
  String descripcion;
  int audUsuarioI;
  int? fila;
  int? pagina;
  int? tamanoPagina;
  int? totalPaginas;
  String? search;
  int? totalRegistros;
  int? codEmpresa;

  AnticipoDetalleModel({
    required this.codAntDetalle,
    required this.codAnticipo,
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.monto,
    required this.codAutorizacion,
    required this.estadoAnticipo,
    required this.fechaAnticipo,
    required this.descripcion,
    required this.audUsuarioI,
    this.fila,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.search,
    this.totalRegistros,
    this.codEmpresa,
  });

  factory AnticipoDetalleModel.fromJson(Map<String, dynamic> json) =>
      AnticipoDetalleModel(
        codAntDetalle: json["codAntDetalle"] ?? 0,
        codAnticipo: json["codAnticipo"] ?? 0,
        codEmpleado: json["codEmpleado"] ?? 0,
        nombreCompleto: json["nombreCompleto"] ?? '',
        monto: json["monto"]?.toDouble() ?? 0.0,
        codAutorizacion: json["codAutorizacion"] ?? 0,
        estadoAnticipo: json["estadoAnticipo"] ?? '',
        fechaAnticipo:
            json["fechaAnticipo"] != null
                ? DateTime.tryParse(json["fechaAnticipo"]) ?? DateTime.now()
                : DateTime.now(),
        descripcion: json["descripcion"] ?? '',
        audUsuarioI: json["audUsuarioI"] ?? 0,
        fila: json["fila"] ?? 0,
        pagina: json["pagina"] ?? 0,
        tamanoPagina: json["tamanoPagina"] ?? 0,
        totalPaginas: json["totalPaginas"] ?? 0,
        search: json["search"] ?? '',
        totalRegistros: json["totalRegistros"] ?? 0,
        codEmpresa: json["codEmpresa"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "codAntDetalle": codAntDetalle,
    "codAnticipo": codAnticipo,
    "codEmpleado": codEmpleado,
    "nombreCompleto": nombreCompleto,
    "monto": monto,
    "codAutorizacion": codAutorizacion,
    "estadoAnticipo": estadoAnticipo,
    "fechaAnticipo":
        "${fechaAnticipo.year.toString().padLeft(4, '0')}-${fechaAnticipo.month.toString().padLeft(2, '0')}-${fechaAnticipo.day.toString().padLeft(2, '0')}",
    "descripcion": descripcion,
    "audUsuarioI": audUsuarioI,
    "fila": fila,
    "pagina": pagina,
    "tamanoPagina": tamanoPagina,
    "totalPaginas": totalPaginas,
    "search": search,
    "totalRegistros": totalRegistros,
    "codEmpresa": codEmpresa,
  };

  AnticipoDetalleEntity toEntity() => AnticipoDetalleEntity(
    codAntDetalle: codAntDetalle,
    codAnticipo: codAnticipo,
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
    monto: monto,
    codAutorizacion: codAutorizacion,
    estadoAnticipo: estadoAnticipo,
    fechaAnticipo: fechaAnticipo,
    descripcion: descripcion,
    audUsuarioI: audUsuarioI,
    fila: fila,
    pagina: pagina,
    tamanoPagina: tamanoPagina,
    totalPaginas: totalPaginas,
    search: search,
    totalRegistros: totalRegistros,
    codEmpresa: codEmpresa,
  );
  factory AnticipoDetalleModel.fromEntity(AnticipoDetalleEntity entity) =>
      AnticipoDetalleModel(
        codAntDetalle: entity.codAntDetalle,
        codAnticipo: entity.codAnticipo,
        codEmpleado: entity.codEmpleado,
        nombreCompleto: entity.nombreCompleto,
        monto: entity.monto,
        codAutorizacion: entity.codAutorizacion,
        estadoAnticipo: entity.estadoAnticipo,
        fechaAnticipo: entity.fechaAnticipo,
        descripcion: entity.descripcion,
        audUsuarioI: entity.audUsuarioI,
        fila: entity.fila,
        pagina: entity.pagina,
        tamanoPagina: entity.tamanoPagina,
        totalPaginas: entity.totalPaginas,
        search: entity.search,
        totalRegistros: entity.totalRegistros,
        codEmpresa: entity.codEmpresa,
      );
}
