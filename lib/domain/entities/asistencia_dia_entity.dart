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

  /// Minutos de atraso ya calculados en el backend (0 en cualquier día que
  /// no sea TRABAJADO/FALTA — ver `BiometricoController.calcularMinutosAtraso`).
  final int minutosAtraso;

  const AsistenciaDiaEntity({
    required this.fecha,
    required this.estado,
    this.motivo,
    this.horaEntradaEsperada,
    this.horaSalidaEsperada,
    this.horaEntradaReal,
    this.horaSalidaReal,
    this.minutosAtraso = 0,
  });

  bool get esFalta => estado == 'FALTA';
  bool get esJustificado =>
      estado == 'FERIADO' ||
      estado == 'SABADO_LIBRE' ||
      estado == 'PERMISO' ||
      estado == 'VACACION' ||
      estado == 'SIN_HORARIO';

  /// Falta, o trabajó pero con atraso — la marca que se ve en el calendario
  /// (pedido explícito del usuario 2026-09-01: "poné una marca a las celdas
  /// que hay atraso/falta o que tengan problemas").
  bool get tieneProblema => esFalta || minutosAtraso > 0;
}
