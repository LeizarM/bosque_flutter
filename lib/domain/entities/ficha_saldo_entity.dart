// Modulo Permisos RR.HH. (consola administrativa de `trh_permiso`).
// Los nombres llevan sufijo a proposito: en esta app `PermisoEntity` ya significa
// el resumen de dias disponibles que ve el EMPLEADO (`/vacacion/diasDisponibles`,
// ACCION 'H1'). Esto es lo que ve RR.HH. de cualquier empleado (ACCION 'C'), y
// las dos cifras no siempre coinciden —ver D1 en el plan de migracion—.
// Confundirlas es el error caro de este modulo.

/// **Origen:** `p_list_Permiso @ACCION='C'`, un empleado por llamada.
///
/// Los campos `*Txt` los arma el backend (coma decimal, sin ceros a la derecha,
/// sufijo « día»/« días»): el móvil pinta el texto y el escritorio usa el
/// número para ordenar y para pintar en rojo un saldo negativo. No se reformatea
/// acá, así que la app y el reporte dicen exactamente lo mismo.
///
/// La ficha de saldo de un empleado: lo que RR.HH. contesta cuando alguien
/// pregunta *"¿cuántos días tengo?"*.
class FichaSaldoEntity {
  final int codEmpleado;
  final String datoEmpleado;
  final String datoEmpresa;
  final String datoCargo;

  /// `dd/MM/yyyy` **o el literal `'Sin Asignar'`**, tal como lo arma el SP.
  /// Es texto y no fecha a propósito: el 'Sin Asignar' es un dato, no un nulo.
  final String datoFechaBeneficio;

  /// Prosa del SP: «11 Años y 5 Meses».
  final String datoAntiguedad;

  final double diasNoUsados;
  final double diasAbonados;

  /// `diasNoUsados + diasAbonados`. **Lo calcula el backend**: la columna
  /// `totalDias` del SP llega siempre en 0.0.
  final double totalDias;

  final String diasNoUsadosTxt;
  final String diasAbonadosTxt;
  final String totalDiasTxt;

  // ── SUPUESTO D0 — pendiente de confirmación de RR.HH. (ver plan §5) ────────
  //
  // El SP suma **sólo la relación laboral activa**: el 58 % de los permisos y el
  // 49 % de las asignaciones de los empleados activos vive en relaciones
  // anteriores y NO entra en estos números. Se tomó la opción (c) del plan:
  // no se cambia el cálculo, se **rotula** el alcance. Los tres campos que
  // siguen existen para que la pantalla pueda decir «Saldo de la relación
  // laboral actual, desde dd/mm/aaaa · N movimientos anteriores no incluidos».
  //
  // Si RR.HH. confirma que el saldo debe abarcar todas las relaciones, cambia el
  // backend y estos campos se quedan como están: nada de acá se rehace.

  /// La relación laboral cuya historia se está sumando.
  final int datoRelEmplEmprVigente;

  /// Desde cuándo corre esa relación. Null si el backend no la pudo resolver.
  final DateTime? relacionVigenteDesde;

  /// El empleado tuvo contratos anteriores. Dispara el rótulo de alcance.
  final bool tieneRelacionesAnteriores;

  /// Cuántos movimientos (permisos + asignaciones) quedaron fuera del saldo.
  final int movimientosFueraDeRelacionVigente;

  const FichaSaldoEntity({
    required this.codEmpleado,
    required this.datoEmpleado,
    required this.datoEmpresa,
    required this.datoCargo,
    required this.datoFechaBeneficio,
    required this.datoAntiguedad,
    required this.diasNoUsados,
    required this.diasAbonados,
    required this.totalDias,
    required this.diasNoUsadosTxt,
    required this.diasAbonadosTxt,
    required this.totalDiasTxt,
    required this.datoRelEmplEmprVigente,
    this.relacionVigenteDesde,
    required this.tieneRelacionesAnteriores,
    required this.movimientosFueraDeRelacionVigente,
  });

  /// El empleado no tiene fecha de inicio de beneficio cargada.
  ///
  /// Se compara contra el literal del SP porque es el literal del SP: el día que
  /// alguien lo cambie, esto deja de mentir en silencio — muestra el texto crudo.
  bool get tieneFechaBeneficio => datoFechaBeneficio.trim() != 'Sin Asignar';

  /// Debe días. Se pinta con `colorScheme.error`, nunca con un rojo a mano.
  bool get saldoNegativo => totalDias < 0;
}
