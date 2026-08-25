import 'dart:convert';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';

PrestamoResponse prestamoResponseFromJson(String str) =>
    PrestamoResponse.fromJson(json.decode(str));
String prestamoResponseToJson(PrestamoResponse data) =>
    json.encode(data.toJson());

class PrestamoResponse {
  String message;
  List<PrestamoModel> data;
  int status;
  int? idGenerado;

  PrestamoResponse({
    required this.message,
    required this.data,
    required this.status,
    this.idGenerado,
  });

  factory PrestamoResponse.fromJson(Map<String, dynamic> json) {
    List<PrestamoModel> listaData = [];
    int? idGen;

    if (json["data"] != null) {
      if (json["data"] is List) {
        listaData = List<PrestamoModel>.from(
          (json["data"] as List).map((x) => PrestamoModel.fromJson(x)),
        );
      } else if (json["data"] is int) {
        idGen = json["data"];
      }
    }

    return PrestamoResponse(
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

class PrestamoModel {
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
  String estadoAsignacion;
  String? estadoPrestamo;
  int? codPrestamo;
  int? codEmpleado;
  String? nombreEmpleadoAsignado;
  double? saldoPendiente;
  double? numCuotas;
  double? cuotaReferencia;
  String? fecIniPago;
  String? tipoPago;

  // Params Auxiliares
  int? fila;
  int? pagina;
  int? tamanoPagina;
  int? totalPaginas;
  String? search;
  int? totalRegistros;
  String? fechaDesde;
  String? fechaHasta;
  int? mostrarAnulados;
  int? forzar;
  String? xmlCuotas;

  PrestamoModel({
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
    required this.estadoAsignacion,
    this.estadoPrestamo,
    this.codPrestamo,
    this.codEmpleado,
    this.nombreEmpleadoAsignado,
    this.saldoPendiente,
    this.numCuotas,
    this.cuotaReferencia,
    this.fecIniPago,
    this.tipoPago,
    this.fila,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.search,
    this.totalRegistros,
    this.fechaDesde,
    this.fechaHasta,
    this.mostrarAnulados,
    this.forzar,
    this.xmlCuotas,
  });

  factory PrestamoModel.fromJson(Map<String, dynamic> json) => PrestamoModel(
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
    referencia: json["referencia"] ?? '',
    debe: json["debe"]?.toDouble() ?? 0.0,
    haber: json["haber"]?.toDouble() ?? 0.0,
    estadoAsignacion: json["estadoAsignacion"] ?? '',
    estadoPrestamo: json["estadoPrestamo"] ?? '',
    codPrestamo: json["codPrestamo"] ?? 0,
    codEmpleado: json["codEmpleado"] ?? 0,
    nombreEmpleadoAsignado: json["nombreEmpleadoAsignado"] ?? '',
    saldoPendiente: json["saldoPendiente"]?.toDouble() ?? 0.0,
    numCuotas: json["numCuotas"]?.toDouble() ?? 0.0,
    cuotaReferencia: json["cuotaReferencia"]?.toDouble(),
    fecIniPago: json["fecIniPago"]?.toString(),
    tipoPago: json["tipoPago"]?.toString(),
    fila: json["fila"] ?? 0,
    pagina: json["pagina"] ?? 0,
    tamanoPagina: json["tamanoPagina"] ?? 0,
    totalPaginas: json["totalPaginas"] ?? 0,
    search: json["search"] ?? '',
    totalRegistros: json["totalRegistros"] ?? 0,
    fechaDesde: json["fechaDesde"],
    fechaHasta: json["fechaHasta"],
    mostrarAnulados: json["mostrarAnulados"],
    forzar: json["forzar"],
    xmlCuotas: json["xmlCuotas"],
  );

  Map<String, dynamic> toJson() => {
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
    "estadoAsignacion": estadoAsignacion,
    "estadoPrestamo": estadoPrestamo,
    "codPrestamo": codPrestamo,
    "codEmpleado": codEmpleado,
    "nombreEmpleadoAsignado": nombreEmpleadoAsignado,
    "saldoPendiente": saldoPendiente,
    "numCuotas": numCuotas,
    "cuotaReferencia": cuotaReferencia,
    "fecIniPago": fecIniPago,
    "tipoPago": tipoPago,
    "fila": fila,
    "pagina": pagina,
    "tamanoPagina": tamanoPagina,
    "totalPaginas": totalPaginas,
    "search": search,
    "totalRegistros": totalRegistros,
    "fechaDesde": fechaDesde,
    "fechaHasta": fechaHasta,
    "mostrarAnulados": mostrarAnulados,
    "forzar": forzar,
    "xmlCuotas": xmlCuotas,
  };

  PrestamoEntity toEntity() => PrestamoEntity(
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
    estadoAsignacion: estadoAsignacion,
    estadoPrestamo: estadoPrestamo,
    codPrestamo: codPrestamo,
    codEmpleado: codEmpleado,
    nombreEmpleadoAsignado: nombreEmpleadoAsignado,
    saldoPendiente: saldoPendiente,
    numCuotas: numCuotas,
    cuotaReferencia: cuotaReferencia,
    fecIniPago: fecIniPago,
    tipoPago: tipoPago,
    fila: fila,
    pagina: pagina,
    tamanoPagina: tamanoPagina,
    totalPaginas: totalPaginas,
    search: search,
    totalRegistros: totalRegistros,
    fechaDesde: fechaDesde,
    fechaHasta: fechaHasta,
    mostrarAnulados: mostrarAnulados,
    forzar: forzar,
    xmlCuotas: xmlCuotas,
  );

  factory PrestamoModel.fromEntity(PrestamoEntity entity) => PrestamoModel(
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
    estadoAsignacion: entity.estadoAsignacion,
    estadoPrestamo: entity.estadoPrestamo,
    codPrestamo: entity.codPrestamo,
    codEmpleado: entity.codEmpleado,
    nombreEmpleadoAsignado: entity.nombreEmpleadoAsignado,
    saldoPendiente: entity.saldoPendiente,
    numCuotas: entity.numCuotas,
    cuotaReferencia: entity.cuotaReferencia,
    fecIniPago: entity.fecIniPago,
    tipoPago: entity.tipoPago,
    fila: entity.fila,
    pagina: entity.pagina,
    tamanoPagina: entity.tamanoPagina,
    totalPaginas: entity.totalPaginas,
    search: entity.search,
    totalRegistros: entity.totalRegistros,
    fechaDesde: entity.fechaDesde,
    fechaHasta: entity.fechaHasta,
    mostrarAnulados: entity.mostrarAnulados,
    forzar: entity.forzar,
    xmlCuotas: entity.xmlCuotas,
  );
}
