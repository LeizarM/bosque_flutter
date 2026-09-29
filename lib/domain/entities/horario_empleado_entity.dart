class HorarioEmpleadoEntity {
  final int codEmpleado;
  final int? codPersona;
  final String? nombreCompleto;
  final String? cargo;
  final int? posicionCargo;
  final String? nombreHorario;
  final String? horaIngreso;
  final String? horaSalida;
  final int? cantMinutos;

  HorarioEmpleadoEntity({
    required this.codEmpleado,
    this.codPersona,
    this.nombreCompleto,
    this.cargo,
    this.posicionCargo,
    this.nombreHorario,
    this.horaIngreso,
    this.horaSalida,
    this.cantMinutos,
  });
}
