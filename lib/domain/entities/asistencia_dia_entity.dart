/// Origen: `POST /biometrico/reporte-mensual` -> `AsistenciaDiaDto` del backend.
///
/// Un dia del reporte de asistencia de un empleado, ya resuelto en el
/// backend (feriados, sabados libres, permisos/vacaciones y el horario
/// vigente ESE dia, no el ultimo asignado en el mes).
class AsistenciaDiaEntity {
  final DateTime fecha;

  /// TRABAJADO | FALTA | FERIADO | SABADO_LIBRE | PERMISO | VACACION | SIN_HORARIO.
  final String estado;
  final String? motivo;

  final DateTime? horaEntradaEsperada;
  final DateTime? horaSalidaEsperada;
  final DateTime? horaEntradaReal;
  final DateTime? horaSalidaReal;

  const AsistenciaDiaEntity({
    required this.fecha,
    required this.estado,
    this.motivo,
    this.horaEntradaEsperada,
    this.horaSalidaEsperada,
    this.horaEntradaReal,
    this.horaSalidaReal,
  });

  bool get esFalta => estado == 'FALTA';
  bool get esJustificado =>
      estado == 'FERIADO' ||
      estado == 'SABADO_LIBRE' ||
      estado == 'PERMISO' ||
      estado == 'VACACION' ||
      estado == 'SIN_HORARIO';
}
