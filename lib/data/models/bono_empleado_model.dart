import 'package:bosque_flutter/domain/entities/bono_empleado_entity.dart';

class BonoEmpleadoModel {
  int codBonEmp;
  int codBono;
  int codEmpleado;
  double monto;
  int audUsuarioI;
  String nombreCompleto;
  int fila;
  int totalRegistros;
  int totalPaginas;

  BonoEmpleadoModel({
    required this.codBonEmp,
    required this.codBono,
    required this.codEmpleado,
    required this.monto,
    required this.audUsuarioI,
    required this.nombreCompleto,
    required this.fila,
    required this.totalRegistros,
    required this.totalPaginas,
  });

  factory BonoEmpleadoModel.fromJson(Map<String, dynamic> json) {
    return BonoEmpleadoModel(
      codBonEmp: json['codBonEmp'] ?? 0,
      codBono: json['codBono'] ?? 0,
      codEmpleado: json['codEmpleado'] ?? 0,
      monto: (json['monto'] ?? 0).toDouble(),
      audUsuarioI: json['audUsuarioI'] ?? 0,
      nombreCompleto: json['nombreCompleto'] ?? '',
      fila: json['fila'] ?? 0,
      totalRegistros: json['totalRegistros'] ?? 0,
      totalPaginas: json['totalPaginas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codBonEmp': codBonEmp,
      'codBono': codBono,
      'codEmpleado': codEmpleado,
      'monto': monto,
      'audUsuarioI': audUsuarioI,
      'nombreCompleto': nombreCompleto,
      'fila': fila,
      'totalRegistros': totalRegistros,
      'totalPaginas': totalPaginas,
    };
  }

  BonoEmpleadoEntity toEntity() => BonoEmpleadoEntity(
    codBonEmp: codBonEmp,
    codBono: codBono,
    codEmpleado: codEmpleado,
    monto: monto,
    audUsuarioI: audUsuarioI,
    nombreCompleto: nombreCompleto,
    fila: fila,
    totalRegistros: totalRegistros,
    totalPaginas: totalPaginas,
  );

  factory BonoEmpleadoModel.fromEntity(BonoEmpleadoEntity entity) =>
      BonoEmpleadoModel(
        codBonEmp: entity.codBonEmp,
        codBono: entity.codBono,
        codEmpleado: entity.codEmpleado,
        monto: entity.monto,
        audUsuarioI: entity.audUsuarioI,
        nombreCompleto: entity.nombreCompleto,
        fila: entity.fila,
        totalRegistros: entity.totalRegistros,
        totalPaginas: entity.totalPaginas,
      );
}
