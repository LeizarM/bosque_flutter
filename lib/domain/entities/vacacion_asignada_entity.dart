// Modulo Permisos RR.HH. (consola administrativa de `trh_permiso`).
// Ver la nota de nombres en `ficha_saldo_entity.dart`.

/// **Origen:** `p_list_vacacionAsignada @ACCION='B'` — una fila por aniversario
/// de la relación laboral, mezclando las filas **reales** de
/// `trh_vacacionAsignada` con filas **sintéticas** que el SP inventa
/// (`codVacacionAsignada = 0`) por cada aniversario que todavía no tiene
/// registro.
///
/// **La fecha no es libre y no se tipea.** Sale del aniversario que armó el SP;
/// en el modal legacy el campo va `disabled="true"`. El alta sólo se ofrece
/// sobre una fila sintética, y lo único que se completa son los días y el
/// motivo — por eso [copyWith] deja tocar sólo esos dos.
///
/// **No es la única que escribe esta tabla.** 1.155 de sus 1.424 filas las puso
/// un proceso automático (`audUsuarioI = -1`, día 1 de cada mes a las 07:00), y
/// ya hay filas fechadas en 2026. Después de escribir hay que releer: el SP no
/// devuelve el id generado y la grilla no es dueña de la tabla.
///
/// Lo que la empresa le **debe** a alguien: los días que le tocan por un año
/// cumplido de antigüedad.
class VacacionAsignadaEntity {
  /// `0` = fila sintética (un aniversario sin registro): la grilla ofrece
  /// **Nuevo**. `> 0` = fila real: ofrece **Editar**. Es la misma regla que el
  /// legacy resuelve en el xhtml con el tercer parámetro de `esAutorizadoB`.
  final int codVacacionAsignada;

  final int codEmpleado;

  /// La relación laboral a la que pertenece la fila.
  ///
  /// **El UPDATE del SP la deja fuera a propósito** (está comentada): moverla
  /// le cambiaría el saldo a dos persona-relación a la vez, porque todas las
  /// lecturas filtran por relación vigente. Es fija en la edición.
  final int codRelEmplEmpr;

  /// **Cero es un valor válido**, no un dato faltante: 446 de las 1.424 filas
  /// valen 0 y significan «este año no le corresponde nada». Por eso el umbral
  /// del alta es `>= 0` y no `> 0` (en el abono de días es al revés).
  final double diasAsignados;

  /// Formateado por el backend (`Fmt.dias`), igual que en la ficha de saldo: la
  /// app y el reporte tienen que decir el mismo número.
  final String diasAsignadosTxt;

  /// Obligatorio y `varchar(300)` NOT NULL en la tabla. Ver [problema].
  final String motivo;

  /// El aniversario. Null sólo si el backend no la pudo resolver.
  final DateTime? fecha;

  final String datoEmpleado;

  /// «Desde la fecha : dd/MM/yyyy», tal como lo arma el SP.
  final String datoRelacion;

  const VacacionAsignadaEntity({
    required this.codVacacionAsignada,
    required this.codEmpleado,
    required this.codRelEmplEmpr,
    required this.diasAsignados,
    this.diasAsignadosTxt = '',
    required this.motivo,
    this.fecha,
    this.datoEmpleado = '',
    this.datoRelacion = '',
  });

  /// Largo de `trh_vacacionAsignada.motivo`. Pasarse **no da un error de
  /// negocio**: revienta el SP con «String or binary data would be truncated»,
  /// que en pantalla se lee como si se hubiera roto el sistema.
  static const int motivoMaximo = 300;

  /// Fuera de todo lo visto en 10 años (0 a 30 días). No prohíbe: la pantalla
  /// avisa y pide confirmar, porque el dato raro puede ser legítimo.
  static const double diasSospechosos = 30;

  /// El aniversario todavía no tiene registro: la grilla ofrece **Nuevo**.
  bool get esSintetica => codVacacionAsignada <= 0;

  /// Qué le falta para poder guardarse, o `null` si está lista.
  ///
  /// **Replica el orden y los umbrales del legacy** (`WizardPermiso.saveVacAsign`),
  /// que corta en el primer fallo. Los mensajes sí se reescriben: los del legacy
  /// («No la cantidad de dia es menor a cero») no se entienden.
  ///
  /// Esto **no autoriza nada**: la validación que cuenta es la de Java, porque
  /// el SP no valida absolutamente nada. Esto es para no viajar al servidor a
  /// buscar un error que ya se ve desde acá.
  String? get problema {
    if (codEmpleado <= 0) return 'No se eligió al empleado.';
    // `>= 0` y no `> 0`: cero es válido y se usa de verdad.
    if (diasAsignados < 0) return 'Los días asignados no pueden ser negativos.';
    if (codRelEmplEmpr <= 0) {
      return 'No se pudo determinar la relación laboral del empleado.';
    }
    final m = motivo.trim();
    if (m.length < 2) return 'Escribí el motivo de la asignación.';
    if (m.length > motivoMaximo) {
      return 'El motivo no puede pasar de $motivoMaximo caracteres '
          '(tiene ${m.length}).';
    }
    return null;
  }

  /// Sólo los dos campos que el modal deja editar.
  ///
  /// **No hay `copyWith` completo a propósito.** El UPDATE del SP no toca
  /// `codEmpleado` (ni siquiera está en el `SET`) ni `codRelEmplEmpr`, y la
  /// fecha la pone el aniversario: un `copyWith` general invitaría a mandar
  /// cambios que el servidor va a ignorar en silencio.
  VacacionAsignadaEntity copyWith({double? diasAsignados, String? motivo}) =>
      VacacionAsignadaEntity(
        codVacacionAsignada: codVacacionAsignada,
        codEmpleado: codEmpleado,
        codRelEmplEmpr: codRelEmplEmpr,
        diasAsignados: diasAsignados ?? this.diasAsignados,
        diasAsignadosTxt: diasAsignadosTxt,
        motivo: motivo ?? this.motivo,
        fecha: fecha,
        datoEmpleado: datoEmpleado,
        datoRelacion: datoRelacion,
      );
}
