import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';

class EmpleadoCargoEntity {
  final int codEmpleado;
  final int codCargoSucursal;
  final int codCargoSucPlanilla;
  final DateTime? fechaInicio;
  final int audUsuario;
  final CargoSucursalEntity? cargoSucursal;
  final String cargoPlanilla;
  final int? existe;
  final DateTime? fechaInicioOriginal;


  EmpleadoCargoEntity({
    required this.codEmpleado,
    required this.codCargoSucursal,
    required this.codCargoSucPlanilla,
    this.fechaInicio,
    required this.audUsuario,
    this.cargoSucursal,
    required this.cargoPlanilla,
    this.existe,
    this.fechaInicioOriginal,
  });
  //metodo to json
  Map<String, dynamic> toJson() {
    return {
      'codEmpleado': codEmpleado,
      'codCargoSucursal': codCargoSucursal,
      'codCargoSucPlanilla': codCargoSucPlanilla,
      'fechaInicio': fechaInicio?.toIso8601String(),
      'audUsuario': audUsuario,
      'existe': existe,
      'fechaInicioOriginal': fechaInicioOriginal?.toIso8601String(),
    };
  }
  //metodo copywith
  EmpleadoCargoEntity copyWith({
    int? codEmpleado,
    int? codCargoSucursal,
    int? codCargoSucPlanilla,
    DateTime? fechaInicio,
    int? audUsuario,
    CargoSucursalEntity? cargoSucursal,
    String? cargoPlanilla,
    int? existe,
    DateTime? fechaInicioOriginal,
  }) {
    return EmpleadoCargoEntity(
      codEmpleado: codEmpleado ?? this.codEmpleado,
      codCargoSucursal: codCargoSucursal ?? this.codCargoSucursal,
      codCargoSucPlanilla: codCargoSucPlanilla ?? this.codCargoSucPlanilla,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      audUsuario: audUsuario ?? this.audUsuario,
      cargoSucursal: cargoSucursal ?? this.cargoSucursal,
      cargoPlanilla: cargoPlanilla ?? this.cargoPlanilla,
      existe: existe ?? this.existe,
      fechaInicioOriginal: fechaInicioOriginal ?? this.fechaInicioOriginal,
    );
  }
}