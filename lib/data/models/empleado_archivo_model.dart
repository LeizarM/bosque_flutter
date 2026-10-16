import 'package:bosque_flutter/domain/entities/empleado_archivo_entity.dart';

class EmpleadoArchivoModel {
  final int codEmpleado;
  final String nombreCompleto;
  final String? cargo;
  final bool activo;

  const EmpleadoArchivoModel({
    required this.codEmpleado,
    required this.nombreCompleto,
    this.cargo,
    this.activo = true,
  });

  factory EmpleadoArchivoModel.fromJson(Map<String, dynamic> json) =>
      EmpleadoArchivoModel(
        codEmpleado: (json['codEmpleado'] as num?)?.toInt() ?? 0,
        nombreCompleto: (json['nombreCompleto'] ?? '').toString(),
        cargo: json['cargo'] as String?,
        activo: json['activo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'codEmpleado': codEmpleado,
    'nombreCompleto': nombreCompleto,
    'cargo': cargo,
    'activo': activo,
  };

  EmpleadoArchivoEntity toEntity() => EmpleadoArchivoEntity(
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
    cargo: cargo,
    activo: activo,
  );
}
