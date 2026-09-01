/// Origen: `POST /biometrico/reporte-mensual-resumen` -> `ResumenAsistenciaEmpleadoDto`.
///
/// Una fila del resumen mensual: un empleado, los totales de su mes. Para el
/// detalle día-por-día de esta persona, usar `reporteMensual` (mismo mes,
/// `codEmpleado`).
///
/// Columnas alineadas con el legacy ("Empleado / Días Asignados / Días NO
/// Marcados / Atrasos / Observaciones"), pero con los valores corregidos:
/// [diasNoMarcados] y [minutosAtraso] ya excluyen los días que no eran una
/// obligación real (feriado, sábado que no le tocaba, permiso, vacación) — el
/// legacy los contaba como falta/atraso igual.
class ResumenAsistenciaEmpleadoEntity {
  final BigInt codEmpleado;
  final String nombreEmpleado;

  /// Días del mes con horario asignado — incluye feriados/permisos, no sólo los trabajados.
  final int diasAsignados;

  /// Días realmente sin marcar (falta real) — ya sin sábados que no le tocaban ni feriados/permisos.
  final int diasNoMarcados;

  /// Suma de minutos de atraso del mes — 0 en los días que no eran obligación real.
  final int minutosAtraso;

  /// Resumen corto de por qué hay días "sin exigencia" (feriados, permisos, sábados libres...), o null si no hay ninguno.
  final String? observaciones;

  const ResumenAsistenciaEmpleadoEntity({
    required this.codEmpleado,
    required this.nombreEmpleado,
    required this.diasAsignados,
    required this.diasNoMarcados,
    required this.minutosAtraso,
    this.observaciones,
  });
}
