import 'package:bosque_flutter/domain/entities/bono_entity.dart';

class BonoResponse {
  final int error;
  final String errormsg;
  final int idGenerado;

  BonoResponse({
    required this.error,
    required this.errormsg,
    required this.idGenerado,
  });

  factory BonoResponse.fromJson(Map<String, dynamic> json) {
    return BonoResponse(
      error: json['error'] ?? json['status'] ?? 99,
      errormsg: json['errormsg'] ?? json['message'] ?? 'Error desconocido',
      idGenerado: json['idGenerado'] ?? json['data'] ?? 0,
    );
  }
}

class BonoModel {
  int codBono;
  DateTime? fechaCreacion;
  String descripcion;
  String estado;
  DateTime? fechaEjecucion;
  String tipoBono;
  double montoTotal;
  int audUsuarioI;
  int fila;
  int totalRegistros;
  int totalPaginas;

  BonoModel({
    required this.codBono,
    this.fechaCreacion,
    required this.descripcion,
    required this.estado,
    this.fechaEjecucion,
    required this.tipoBono,
    required this.montoTotal,
    required this.audUsuarioI,
    required this.fila,
    required this.totalRegistros,
    required this.totalPaginas,
  });

  factory BonoModel.fromJson(Map<String, dynamic> json) {
    return BonoModel(
      codBono: json['codBono'] ?? 0,
      fechaCreacion:
          json['fechaCreacion'] != null
              ? DateTime.parse(json['fechaCreacion'])
              : null,
      descripcion: json['descripcion'] ?? '',
      estado: json['estado'] ?? '',
      fechaEjecucion:
          json['fechaEjecucion'] != null
              ? DateTime.parse(json['fechaEjecucion'])
              : null,
      tipoBono: json['tipoBono'] ?? '',
      montoTotal: (json['montoTotal'] ?? 0).toDouble(),
      audUsuarioI: json['audUsuarioI'] ?? 0,
      fila: json['fila'] ?? 0,
      totalRegistros: json['totalRegistros'] ?? 0,
      totalPaginas: json['totalPaginas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codBono': codBono,
      'fechaCreacion': fechaCreacion?.toIso8601String(),
      'descripcion': descripcion,
      'estado': estado,
      'fechaEjecucion': fechaEjecucion?.toIso8601String(),
      'tipoBono': tipoBono,
      'montoTotal': montoTotal,
      'audUsuarioI': audUsuarioI,
      'fila': fila,
      'totalRegistros': totalRegistros,
      'totalPaginas': totalPaginas,
    };
  }

  BonoEntity toEntity() => BonoEntity(
    codBono: codBono,
    fechaCreacion: fechaCreacion,
    descripcion: descripcion,
    estado: estado,
    fechaEjecucion: fechaEjecucion,
    tipoBono: tipoBono,
    montoTotal: montoTotal,
    audUsuarioI: audUsuarioI,
    fila: fila,
    totalRegistros: totalRegistros,
    totalPaginas: totalPaginas,
  );

  factory BonoModel.fromEntity(BonoEntity entity) => BonoModel(
    codBono: entity.codBono,
    fechaCreacion: entity.fechaCreacion,
    descripcion: entity.descripcion,
    estado: entity.estado,
    fechaEjecucion: entity.fechaEjecucion,
    tipoBono: entity.tipoBono,
    montoTotal: entity.montoTotal,
    audUsuarioI: entity.audUsuarioI,
    fila: entity.fila,
    totalRegistros: entity.totalRegistros,
    totalPaginas: entity.totalPaginas,
  );
}
