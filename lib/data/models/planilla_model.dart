import 'package:bosque_flutter/domain/entities/planilla_entity.dart';

class PlanillaResponse {
  final int error;
  final String errormsg;
  final int idGenerado;

  PlanillaResponse({
    required this.error,
    required this.errormsg,
    required this.idGenerado,
  });

  factory PlanillaResponse.fromJson(Map<String, dynamic> json) {
    return PlanillaResponse(
      error: json['error'] ?? json['status'] ?? 99,
      errormsg: json['errormsg'] ?? json['message'] ?? 'Error desconocido',
      idGenerado: json['idGenerado'] ?? json['data'] ?? 0,
    );
  }
}

class PlanillaModel {
  int codPlanilla;
  DateTime? fechaPeriodo;
  DateTime? fechaEjecucion;
  String estado;
  int codEmpresa;
  String empresa;
  int codSeguro;
  String caja;
  double totalLiquido;
  int fila;
  int totalRegistros;
  int totalPaginas;

  PlanillaModel({
    required this.codPlanilla,
    this.fechaPeriodo,
    this.fechaEjecucion,
    required this.estado,
    required this.codEmpresa,
    required this.empresa,
    required this.codSeguro,
    required this.caja,
    required this.totalLiquido,
    required this.fila,
    required this.totalRegistros,
    required this.totalPaginas,
  });

  factory PlanillaModel.fromJson(Map<String, dynamic> json) {
    return PlanillaModel(
      codPlanilla: json['codPlanilla'] ?? 0,
      fechaPeriodo:
          json['fechaPeriodo'] != null
              ? DateTime.parse(json['fechaPeriodo'])
              : null,
      fechaEjecucion:
          json['fechaEjecucion'] != null
              ? DateTime.parse(json['fechaEjecucion'])
              : null,
      estado: json['estado'] ?? '',
      codEmpresa: json['codEmpresa'] ?? 0,
      empresa: json['empresa'] ?? '',
      codSeguro: json['codSeguro'] ?? 0,
      caja: json['caja'] ?? '',
      totalLiquido: (json['totalLiquido'] ?? 0).toDouble(),
      fila: json['fila'] ?? 0,
      totalRegistros: json['totalRegistros'] ?? 0,
      totalPaginas: json['totalPaginas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codPlanilla': codPlanilla,
      'fechaPeriodo': fechaPeriodo?.toIso8601String(),
      'fechaEjecucion': fechaEjecucion?.toIso8601String(),
      'estado': estado,
      'codEmpresa': codEmpresa,
      'empresa': empresa,
      'codSeguro': codSeguro,
      'caja': caja,
      'totalLiquido': totalLiquido,
      'fila': fila,
      'totalRegistros': totalRegistros,
      'totalPaginas': totalPaginas,
    };
  }

  PlanillaEntity toEntity() => PlanillaEntity(
    codPlanilla: codPlanilla,
    fechaPeriodo: fechaPeriodo,
    fechaEjecucion: fechaEjecucion,
    estado: estado,
    codEmpresa: codEmpresa,
    empresa: empresa,
    codSeguro: codSeguro,
    caja: caja,
    totalLiquido: totalLiquido,
    fila: fila,
    totalRegistros: totalRegistros,
    totalPaginas: totalPaginas,
  );
}
