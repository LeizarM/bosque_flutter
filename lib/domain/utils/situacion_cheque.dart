/// En que punto de su cobro esta un cheque. Es un dato de pantalla: se deriva de
/// campos que ya vienen en la fila (estado y fecha de cobro) y no se guarda ni se
/// manda a ningun lado.
enum SituacionCheque {
  /// Estado CER. No se evalua por fecha: ya no hay nada que cobrar.
  cerrado,

  /// Pendiente con la fecha de cobro anterior a hoy.
  atrasado,

  /// Pendiente que se cobra hoy.
  cobraHoy,

  /// Pendiente que se cobra de aqui a [diasPorCobrarCheque] dias.
  porCobrar,

  /// Pendiente que se cobra mas adelante.
  vigente,

  /// Pendiente sin fecha de cobro: no hay con que comparar.
  sinFecha,
}

/// Hasta cuantos dias de anticipacion un pendiente cuenta como «por cobrar».
const int diasPorCobrarCheque = 7;

/// La situacion de un cheque y los dias que faltan (o pasaron) para su cobro.
class SituacionDeCheque {
  const SituacionDeCheque(this.situacion, {this.dias});

  final SituacionCheque situacion;

  /// Dias de hoy a la fecha de cobro: positivo = faltan, 0 = hoy, negativo =
  /// pasaron. Null cuando no se evalua (cerrado, sin fecha).
  final int? dias;

  /// Lo que mas urge: ya paso de fecha o se cobra hoy.
  bool get esUrgente =>
      situacion == SituacionCheque.atrasado ||
      situacion == SituacionCheque.cobraHoy;

  /// Es un pendiente con fecha, o sea, tiene un plazo que mirar.
  bool get tienePlazo => dias != null;

  /// El texto corto de una celda: «Atrasado 12 d», «Cobra hoy», «En 3 d».
  ///
  /// La «d» es la misma en singular y en plural, asi «En 1 d» y «En 3 d» se
  /// leen igual de bien. Nunca dice «vencido»: en este modulo VEN es una accion
  /// de postergacion de la fecha de cobro y la palabra confundiria.
  String get texto => switch (situacion) {
    SituacionCheque.cerrado => 'Cerrado',
    SituacionCheque.atrasado => 'Atrasado ${-dias!} d',
    SituacionCheque.cobraHoy => 'Cobra hoy',
    SituacionCheque.porCobrar || SituacionCheque.vigente => 'En $dias d',
    SituacionCheque.sinFecha => 'Sin fecha',
  };

  /// La misma frase completa, con singular y plural, para el tooltip y los
  /// lectores de pantalla.
  String get textoLargo => switch (situacion) {
    SituacionCheque.cerrado => 'Cerrado',
    SituacionCheque.atrasado =>
      'Atrasado ${-dias!} ${-dias! == 1 ? 'día' : 'días'}',
    SituacionCheque.cobraHoy => 'Cobra hoy',
    SituacionCheque.porCobrar || SituacionCheque.vigente =>
      dias == 1 ? 'Cobra mañana' : 'Cobra en $dias días',
    SituacionCheque.sinFecha => 'Sin fecha de cobro',
  };

  @override
  bool operator ==(Object other) =>
      other is SituacionDeCheque &&
      other.situacion == situacion &&
      other.dias == dias;

  @override
  int get hashCode => Object.hash(situacion, dias);

  @override
  String toString() => 'SituacionDeCheque($situacion, dias: $dias)';
}

/// Calcula la situacion de un cheque.
///
/// - **Solo el dia cuenta**: se compara `hoy` con la fecha de cobro sin hora (la
///   columna es `date` y el reloj trae hora; sin recortarla, un cheque que se
///   cobra hoy aparecia como «atrasado» pasado el mediodia). Se hace en UTC para
///   que un cambio de hora no mueva un dia.
/// - **El reloj entra por parametro** ([hoy]): la pantalla lo toma de
///   `relojChequesProvider`, y asi las pruebas no dependen del dia en que corren.
/// - **Cerrado es cerrado.** Un cheque CER no se evalua por fecha. Cualquier otro
///   estado se trata como abierto, que es lo que hace el resto del modulo (los
///   permisos preguntan por «distinto de CER»): el alta lo deja en PEN y no hay
///   un tercer estado.
SituacionDeCheque situacionDeCheque({
  required String? estado,
  required DateTime? fechaCobrar,
  required DateTime hoy,
}) {
  if ((estado ?? '').trim() == 'CER') {
    return const SituacionDeCheque(SituacionCheque.cerrado);
  }
  if (fechaCobrar == null) {
    return const SituacionDeCheque(SituacionCheque.sinFecha);
  }

  final dia = DateTime.utc(hoy.year, hoy.month, hoy.day);
  final cobro = DateTime.utc(
    fechaCobrar.year,
    fechaCobrar.month,
    fechaCobrar.day,
  );
  final dias = cobro.difference(dia).inDays;

  if (dias < 0) return SituacionDeCheque(SituacionCheque.atrasado, dias: dias);
  if (dias == 0) {
    return const SituacionDeCheque(SituacionCheque.cobraHoy, dias: 0);
  }
  if (dias <= diasPorCobrarCheque) {
    return SituacionDeCheque(SituacionCheque.porCobrar, dias: dias);
  }
  return SituacionDeCheque(SituacionCheque.vigente, dias: dias);
}
