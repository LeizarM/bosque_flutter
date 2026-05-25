// To parse this JSON data, do
//
//     final anticipoModel = anticipoModelFromJson(jsonString);

import 'dart:convert';

import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';

// Funciones de ayuda para conversión
AnticipoResponse anticipoResponseFromJson(String str) =>
    AnticipoResponse.fromJson(json.decode(str));
String anticipoResponseToJson(AnticipoResponse data) =>
    json.encode(data.toJson());

class AnticipoResponse {
  String message;
  List<AnticipoModel> data;
  int status;
  int? idGenerado;

  AnticipoResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory AnticipoResponse.fromJson(Map<String, dynamic> json) {
    List<AnticipoModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<AnticipoModel>.from(
          (json["data"] as List).map((x) => AnticipoModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return AnticipoResponse(
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

class AnticipoModel {
  int codAnticipo;
  int codEmpresa;
  String db;
  String codigoCuenta;
  String nombreCuenta;
  DateTime fechaAsiento;
  String numAsiento;
  String concepto;
  String referencia;
  double debe;
  double haber;
  String estado;
  int audUsuario;
  int? fila;
  int? pagina;
  int? tamanoPagina;
  int? totalPaginas;
  String? search;
  int? totalRegistros;
  String? moduloOrigen;
  String? anio;
  String? mes;

  AnticipoModel({
    required this.codAnticipo,
    required this.codEmpresa,
    required this.db,
    required this.codigoCuenta,
    required this.nombreCuenta,
    required this.fechaAsiento,
    required this.numAsiento,
    required this.concepto,
    required this.referencia,
    required this.debe,
    required this.haber,
    required this.estado,
    required this.audUsuario,
    this.fila,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.search,
    this.totalRegistros,
    this.moduloOrigen,
    this.anio,
    this.mes,
  });

  factory AnticipoModel.fromJson(Map<String, dynamic> json) => AnticipoModel(
    codAnticipo: json["codAnticipo"] ?? 0,
    codEmpresa: json["codEmpresa"] ?? 0,
    db: json["db"] ?? '',
    codigoCuenta: json["codigoCuenta"] ?? '',
    nombreCuenta: json["nombreCuenta"] ?? '',
    fechaAsiento:
        json["fechaAsiento"] != null
            ? DateTime.tryParse(json["fechaAsiento"]) ?? DateTime.now()
            : DateTime.now(),
    numAsiento: json["numAsiento"] ?? '',
    concepto: json["concepto"] ?? '',
    referencia: json["referencia"] ?? json["referencia1"] ?? '',
    debe: json["debe"]?.toDouble() ?? 0.0,
    haber: json["haber"]?.toDouble() ?? 0.0,
    estado: json["estado"] ?? '',
    audUsuario: json["audUsuarioI"] ?? json["audUsuario"] ?? 0,
    fila: json["fila"] ?? 0,
    pagina: json["pagina"] ?? 0,
    tamanoPagina: json["tamanoPagina"] ?? 0,
    totalPaginas: json["totalPaginas"] ?? 0,
    search: json["search"] ?? '',
    totalRegistros: json["totalRegistros"] ?? 0,
    moduloOrigen: json["moduloOrigen"] ?? json["origen"],
    anio: json["anio"]?.toString(),
    mes: json["mes"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "codAnticipo": codAnticipo,
    "codEmpresa": codEmpresa,
    "db": db,
    "codigoCuenta": codigoCuenta,
    "nombreCuenta": nombreCuenta,
    "fechaAsiento":
        "${fechaAsiento.year.toString().padLeft(4, '0')}-${fechaAsiento.month.toString().padLeft(2, '0')}-${fechaAsiento.day.toString().padLeft(2, '0')}",
    "numAsiento": numAsiento,
    "concepto": concepto,
    "referencia": referencia,
    "debe": debe,
    "haber": haber,
    "estado": estado,
    "audUsuario": audUsuario,
    "fila": fila,
    "pagina": pagina,
    "tamanoPagina": tamanoPagina,
    "totalPaginas": totalPaginas,
    "search": search,
    "totalRegistros": totalRegistros,
    "moduloOrigen": moduloOrigen,
    "anio": anio,
    "mes": mes,
  };
  AnticipoEntity toEntity() => AnticipoEntity(
    codAnticipo: codAnticipo,
    codEmpresa: codEmpresa,
    db: db,
    codigoCuenta: codigoCuenta,
    nombreCuenta: nombreCuenta,
    fechaAsiento: fechaAsiento,
    numAsiento: numAsiento,
    concepto: concepto,
    referencia: referencia,
    debe: debe,
    haber: haber,
    estado: estado,
    audUsuario: audUsuario,
    fila: fila,
    pagina: pagina,
    tamanoPagina: tamanoPagina,
    totalPaginas: totalPaginas,
    search: search,
    totalRegistros: totalRegistros,
    moduloOrigen: moduloOrigen,
    anio: anio,
    mes: mes,
  );
  factory AnticipoModel.fromEntity(AnticipoEntity entity) => AnticipoModel(
    codAnticipo: entity.codAnticipo,
    codEmpresa: entity.codEmpresa,
    db: entity.db,
    codigoCuenta: entity.codigoCuenta,
    nombreCuenta: entity.nombreCuenta,
    fechaAsiento: entity.fechaAsiento,
    numAsiento: entity.numAsiento,
    concepto: entity.concepto,
    referencia: entity.referencia,
    debe: entity.debe,
    haber: entity.haber,
    estado: entity.estado,
    audUsuario: entity.audUsuario,
    fila: entity.fila,
    pagina: entity.pagina,
    tamanoPagina: entity.tamanoPagina,
    totalPaginas: entity.totalPaginas,
    search: entity.search,
    totalRegistros: entity.totalRegistros,
    moduloOrigen: entity.moduloOrigen,
    anio: entity.anio,
    mes: entity.mes,
  );
}
