// Modulo Permisos RR.HH. (consola administrativa de `trh_permiso`).
// Ver la nota de nombres en `ficha_saldo_entity.dart`.

/// **Origen:** `p_list_AbonoDias` — el detalle de `trh_abonoDias` de un empleado
/// en su relación laboral vigente.
///
/// **Los días abonados son días libres que se cobran igual**: son un *haber*
/// que se le acredita a alguien por fuera de la vacación (una compensación, una
/// regularización). En 10 años hay 184 filas, 9 en 2025 y ninguna en 2026: cada
/// alta acá es un hecho raro, y por eso se confirma.
///
/// **A diferencia de la vacación asignada, acá el cero no existe**: el umbral
/// del legacy es `> 0` estricto y el mínimo real medido en la tabla es 0,5.
class AbonoDiasEntity {
  /// `0` = alta. `> 0` = edición. Lo decide el id, no un flag: es la misma
  /// regla que `AbonoDiasManagedBean.registrar()`.
  final int codAbonoDias;

  final int codEmpleado;

  /// **El UPDATE del SP sí pisa esta columna** (al revés que en vacación
  /// asignada), y `codEmpleado` también. Por eso toda edición manda la fila
  /// entera: una 'U' parcial dejaría `codEmpleado` en NULL sobre una columna
  /// NOT NULL y el UPDATE reventaría.
  final int codRelEmplEmpr;

  final double diasAbonados;

  /// Formateado por el backend (`Fmt.dias`), igual que en la ficha de saldo.
  final String diasAbonadosTxt;

  /// En el alta la elige quien carga; **en la edición no se toca** (el modal
  /// legacy la deja `disabled` cuando `codAbonoDias != 0`).
  final DateTime? fecha;

  /// `varchar(50)`, no 300. Ver [motivoMaximo].
  final String motivo;

  /// `ROW_NUMBER` que devuelve el subreporte. 0 cuando la lista no viene
  /// numerada.
  final int fila;

  /// Acumulado del empleado en esa relación, que el SP repite en cada fila.
  /// Se lee de la primera; con la lista vacía no hay nada que totalizar.
  final double totalDias;
  final String totalDiasTxt;

  const AbonoDiasEntity({
    required this.codAbonoDias,
    required this.codEmpleado,
    required this.codRelEmplEmpr,
    required this.diasAbonados,
    this.diasAbonadosTxt = '',
    this.fecha,
    required this.motivo,
    this.fila = 0,
    this.totalDias = 0,
    this.totalDiasTxt = '',
  });

  /// Largo de `trh_abonoDias.motivo`. **Son 50 y no 300**: el SP declara
  /// `@motivo VARCHAR(50)` y un motivo más largo lo trunca sin avisar o hace
  /// fallar el INSERT. «Compensación por inventario del 21 de septiembre» ya
  /// son 54.
  static const int motivoMaximo = 50;

  /// Fuera del rango visto (0,5 a 22 días, promedio 2,57). Avisa, no prohíbe.
  static const double diasSospechosos = 22;

  /// Es un alta: todavía no existe la fila.
  bool get esAlta => codAbonoDias <= 0;

  /// Qué le falta para poder guardarse, o `null` si está lista.
  ///
  /// Replica `WizardPermiso.saveAbonoDia`, que corta en el primer fallo. **El
  /// umbral es `> 0` estricto**, distinto del de la vacación asignada: confundir
  /// los dos es el error fácil de este módulo.
  String? get problema {
    if (codEmpleado <= 0) return 'No se eligió al empleado.';
    if (diasAbonados <= 0) return 'Los días abonados tienen que ser mayores a 0.';
    if (codRelEmplEmpr <= 0) {
      return 'No se pudo determinar la relación laboral del empleado.';
    }
    if (fecha == null) return 'Elegí la fecha del abono.';
    final m = motivo.trim();
    if (m.length < 2) return 'Escribí el motivo del abono.';
    if (m.length > motivoMaximo) {
      return 'El motivo no puede pasar de $motivoMaximo caracteres '
          '(tiene ${m.length}).';
    }
    return null;
  }

  /// Lo que el modal deja editar. La fecha sólo en el alta: ver [fecha].
  AbonoDiasEntity copyWith({
    double? diasAbonados,
    String? motivo,
    DateTime? fecha,
  }) => AbonoDiasEntity(
    codAbonoDias: codAbonoDias,
    codEmpleado: codEmpleado,
    codRelEmplEmpr: codRelEmplEmpr,
    diasAbonados: diasAbonados ?? this.diasAbonados,
    diasAbonadosTxt: diasAbonadosTxt,
    fecha: fecha ?? this.fecha,
    motivo: motivo ?? this.motivo,
    fila: fila,
    totalDias: totalDias,
    totalDiasTxt: totalDiasTxt,
  );
}
