// Modulo Permisos RR.HH. (consola administrativa de `trh_permiso`).
// Ver la nota de nombres en `ficha_saldo_entity.dart`.

// El unico import de una entity del modulo, y es a otra entity: el desglose ES
// su lista de tramos, asi que separarlos en dos archivos —una clase por archivo,
// como en rol-sabados— obliga a nombrar al tramo desde aca.
import 'package:bosque_flutter/domain/entities/tramo_saldo_entity.dart';

/// **Origen:** `p_list_Permiso @ACCION='D'`, una fila con 20 columnas que el
/// backend arma como cabecera + 5 tramos + totales.
///
/// Las etiquetas de los tramos **las escribe el propio SP** (con `UPDATE`s sobre
/// la tabla temporal) y llegan con las fechas ya adentro: «Saldo hasta el
/// penultimo año cumplido (28/02/2025)». Se muestran **literales**, sin
/// reescribir ni corregir la ortografía: el criterio de aceptación es que sean
/// carácter por carácter iguales a las del modal legacy, que es contra lo que
/// RR.HH. va a comparar.
///
/// De dónde salen los días de un empleado, en los 5 tramos del legacy.
class DesgloseSaldoEntity {
  final int codEmpleado;
  final String datoEmpleado;
  final String datoEmpresa;
  final String datoCargo;
  final String datoAntiguedad;

  /// `dd/MM/yyyy` o el literal `'Sin Asignar'`.
  final String datoFecIniBenef;

  /// Años cumplidos de beneficio. Es la llave de [desgloseAplicable].
  final int datoAnios;

  /// Fin del penúltimo año cumplido. Null si no hay fecha de beneficio.
  final DateTime? fecIniPenUl;

  /// Inicio del último año cumplido. Null si no hay fecha de beneficio.
  final DateTime? fecIniUlt;

  final int codRelEmplEmpr;

  /// El empleado tiene fecha de inicio de beneficio cargada.
  ///
  /// Cuando es `false` los tramos 1 y 4 dan 0 **pero el 2 muestra toda la
  /// historia**: no son cinco ceros, es un desglose corrido. La pantalla tiene
  /// que avisarlo explícitamente.
  final bool tieneFechaBeneficio;

  // ── SUPUESTO D2 — pendiente de confirmación de RR.HH. (ver plan §5) ────────
  //
  // Con `datoAnios < 2` el tramo 2 cae en la rama degenerada del SP: en vez de
  // acotar el año, suma TODAS las asignaciones, y la etiqueta sale con «-1º
  // año cumplido». Hoy le pasa a 57 de 85 empleados activos. Se tomó la opción
  // del plan: un flag explícito, y **cuando es `false` la UI no pinta los 5
  // tramos** — muestra el estado acordado más los tres números que sí son
  // fiables. Mostrarlos igual sería publicar una cifra que nadie puede defender.
  /// `datoAnios >= 2`. Si es `false`, **no mostrar los 5 tramos**.
  final bool desgloseAplicable;

  /// Los 5 tramos, en el orden en que los arma el SP.
  final List<TramoSaldoEntity> tramos;

  // ── SUPUESTO D1 — pendiente de confirmación de RR.HH. (ver plan §5) ────────
  //
  // El total replica exactamente al bean legacy: DEBE = tramo 1 + tramo 2,
  // HABER = tramo 4 + tramo 5, y **el tramo 3 (las duodécimas acumuladas) NO
  // entra**. Es la fuente de la discrepancia con la cifra que ve el empleado.
  // Se tomó la opción (c): se muestran los dos números desglosados y rotulados,
  // y el tramo 3 viaja con `signo == 'INFO'` para que el contrato mismo diga
  // que no suma. Cambiar esto es cambiar el número que RR.HH. compara contra el
  // sistema viejo: no se toca sin acta.
  final double montoTotalDebe;
  final double montoTotalHaber;
  final double montoTotal;
  final String montoTotalTxt;

  /// «TOTAL VACACION NO UTILIZADO», tal como lo dice el legacy.
  final String etiquetaTotal;

  const DesgloseSaldoEntity({
    required this.codEmpleado,
    required this.datoEmpleado,
    required this.datoEmpresa,
    required this.datoCargo,
    required this.datoAntiguedad,
    required this.datoFecIniBenef,
    required this.datoAnios,
    this.fecIniPenUl,
    this.fecIniUlt,
    required this.codRelEmplEmpr,
    required this.tieneFechaBeneficio,
    required this.desgloseAplicable,
    required this.tramos,
    required this.montoTotalDebe,
    required this.montoTotalHaber,
    required this.montoTotal,
    required this.montoTotalTxt,
    required this.etiquetaTotal,
  });

  /// Debe días. Se pinta con `colorScheme.error`.
  bool get saldoNegativo => montoTotal < 0;
}
