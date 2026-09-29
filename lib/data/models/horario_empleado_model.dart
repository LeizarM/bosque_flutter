import 'package:bosque_flutter/domain/entities/horario_empleado_entity.dart';

class HorarioEmpleadoModel extends HorarioEmpleadoEntity {
  HorarioEmpleadoModel({
    required int codEmpleado,
    int? codPersona,
    String? nombreCompleto,
    String? cargo,
    int? posicionCargo,
    String? nombreHorario,
    String? horaIngreso,
    String? horaSalida,
    int? cantMinutos,
  }) : super(
          codEmpleado: codEmpleado,
          codPersona: codPersona,
          nombreCompleto: nombreCompleto,
          cargo: cargo,
          posicionCargo: posicionCargo,
          nombreHorario: nombreHorario,
          horaIngreso: horaIngreso,
          horaSalida: horaSalida,
          cantMinutos: cantMinutos,
        );

  factory HorarioEmpleadoModel.fromJson(Map<String, dynamic> json) {
    return HorarioEmpleadoModel(
      codEmpleado: json['codEmpleado'] ?? 0,
      codPersona: json['codPersona'],
      nombreCompleto: json['nombreCompleto'],
      cargo: json['cargo'],
      posicionCargo: json['posicionCargo'],
      nombreHorario: json['nombreHorario'],
      horaIngreso: json['horaIngreso'],
      horaSalida: json['horaSalida'],
      cantMinutos: json['cantMinutos'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codEmpleado': codEmpleado,
      'codPersona': codPersona,
      'nombreCompleto': nombreCompleto,
      'cargo': cargo,
      'posicionCargo': posicionCargo,
      'nombreHorario': nombreHorario,
      'horaIngreso': horaIngreso,
      'horaSalida': horaSalida,
      'cantMinutos': cantMinutos,
    };
  }

  factory HorarioEmpleadoModel.fromEntity(HorarioEmpleadoEntity entity) {
    return HorarioEmpleadoModel(
      codEmpleado: entity.codEmpleado,
      codPersona: entity.codPersona,
      nombreCompleto: entity.nombreCompleto,
      cargo: entity.cargo,
      posicionCargo: entity.posicionCargo,
      nombreHorario: entity.nombreHorario,
      horaIngreso: entity.horaIngreso,
      horaSalida: entity.horaSalida,
      cantMinutos: entity.cantMinutos,
    );
  }

  HorarioEmpleadoEntity toEntity() {
    return HorarioEmpleadoEntity(
      codEmpleado: codEmpleado,
      codPersona: codPersona,
      nombreCompleto: nombreCompleto,
      cargo: cargo,
      posicionCargo: posicionCargo,
      nombreHorario: nombreHorario,
      horaIngreso: horaIngreso,
      horaSalida: horaSalida,
      cantMinutos: cantMinutos,
    );
  }
}
