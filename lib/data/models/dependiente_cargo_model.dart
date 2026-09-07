// Destino final: lib/data/models/dependiente_cargo_model.dart
import 'package:bosque_flutter/domain/entities/dependiente_cargo_entity.dart';

class DependienteCargoModel {
  final int codCargo;
  final String descripcionCargo;
  final int codNivel;
  final int codEmpresa;
  final int? codCargoSucursal;
  final int codSucursal;
  final String nombreSucursal;
  final int profundidadNivel;
  final int? codEmpleadoActual;
  final String? nombreEmpleadoActual;

  DependienteCargoModel({
    required this.codCargo,
    required this.descripcionCargo,
    required this.codNivel,
    required this.codEmpresa,
    this.codCargoSucursal,
    required this.codSucursal,
    required this.nombreSucursal,
    required this.profundidadNivel,
    this.codEmpleadoActual,
    this.nombreEmpleadoActual,
  });

  factory DependienteCargoModel.fromJson(Map<String, dynamic> json) {
    return DependienteCargoModel(
      codCargo: json['codCargo'] ?? 0,
      descripcionCargo: json['descripcionCargo'] ?? '',
      codNivel: json['codNivel'] ?? 0,
      codEmpresa: json['codEmpresa'] ?? 0,
      codCargoSucursal: json['codCargoSucursal'],
      codSucursal: json['codSucursal'] ?? 0,
      nombreSucursal: json['nombreSucursal'] ?? '',
      profundidadNivel: json['profundidadNivel'] ?? 0,
      codEmpleadoActual: json['codEmpleadoActual'],
      nombreEmpleadoActual: json['nombreEmpleadoActual'],
    );
  }

  DependienteCargoEntity toEntity() => DependienteCargoEntity(
    codCargo: codCargo,
    descripcionCargo: descripcionCargo,
    codNivel: codNivel,
    codEmpresa: codEmpresa,
    codCargoSucursal: codCargoSucursal,
    codSucursal: codSucursal,
    nombreSucursal: nombreSucursal,
    profundidadNivel: profundidadNivel,
    codEmpleadoActual: codEmpleadoActual,
    nombreEmpleadoActual: nombreEmpleadoActual,
  );
}
