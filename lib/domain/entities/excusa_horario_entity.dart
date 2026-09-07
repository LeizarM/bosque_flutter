// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `POST /rol-sabados/refrescar-excusas-horario`.
///
/// Una fila = un participante al que, por horario biométrico (`tbio_*`),
/// ya le tocó tanto o más de su cuota semanal ANTES del sábado -- típicamente
/// porque esa semana tuvo un horario rotativo distinto al suyo de siempre
/// (p.ej. "Horario Extendido") -- así que ese sábado que le tocaba por la
/// rotación A/B se excusa solo.
///
/// [aplicado] distingue el modo previsualización (`soloInformar=true`, no se
/// tocó nada) del modo real: si es `false` y [error] no es vacío, se INTENTÓ
/// excusarlo y falló (rol cerrado a mitad de la corrida, celda tocada por
/// otro justo antes, etc.) — esa fila puntual no quedó aplicada, el resto del
/// lote sí sigue.
class ExcusaHorarioEntity {
  final int codEmpleado;
  final String nombreEmpleado;
  final int idParticipante;
  final int idSabado;
  final DateTime? fecha;
  final double minutosSemana;
  final double minutosCuota;
  final String motivo;
  final bool aplicado;
  final String error;

  const ExcusaHorarioEntity({
    required this.codEmpleado,
    required this.nombreEmpleado,
    required this.idParticipante,
    required this.idSabado,
    this.fecha,
    required this.minutosSemana,
    required this.minutosCuota,
    required this.motivo,
    required this.aplicado,
    required this.error,
  });
}
