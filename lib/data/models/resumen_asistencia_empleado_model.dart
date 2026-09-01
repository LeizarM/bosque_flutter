import 'package:bosque_flutter/domain/entities/resumen_asistencia_empleado_entity.dart';

/// Origen: `POST /biometrico/reporte-mensual-resumen`.
class ResumenAsistenciaEmpleadoModel {
  final BigInt codEmpleado;
  final String nombreEmpleado;
  final int diasAsignados;
  final int diasNoMarcados;
  final int minutosAtraso;
  final String? observaciones;

  const ResumenAsistenciaEmpleadoModel({
    required this.codEmpleado,
    required this.nombreEmpleado,
    required this.diasAsignados,
    required this.diasNoMarcados,
    required this.minutosAtraso,
    this.observaciones,
  });

  factory ResumenAsistenciaEmpleadoModel.fromJson(Map<String, dynamic> json) =>
      ResumenAsistenciaEmpleadoModel(
        codEmpleado:
            json['codEmpleado'] != null
                ? BigInt.from(json['codEmpleado'])
                : BigInt.zero,
        nombreEmpleado: json['nombreEmpleado'] ?? '',
        diasAsignados: json['diasAsignados'] ?? 0,
        diasNoMarcados: json['diasNoMarcados'] ?? 0,
        minutosAtraso: json['minutosAtraso'] ?? 0,
        observaciones: json['observaciones'],
      );

  ResumenAsistenciaEmpleadoEntity toEntity() => ResumenAsistenciaEmpleadoEntity(
    codEmpleado: codEmpleado,
    nombreEmpleado: nombreEmpleado,
    diasAsignados: diasAsignados,
    diasNoMarcados: diasNoMarcados,
    minutosAtraso: minutosAtraso,
    observaciones: observaciones,
  );
}
