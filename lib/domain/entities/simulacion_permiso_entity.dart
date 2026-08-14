// Modulo Permisos RR.HH. (consola administrativa de `trh_permiso`).
// Ver la nota de nombres en `ficha_saldo_entity.dart`.

/// Lo que daría un permiso individual **antes** de grabarlo: los campos
/// calculados en vivo de los modales «Programar permiso» y «Programar
/// vacación», más el aviso de que el rango se cruza con otro permiso.
///
/// **Origen:** `POST /permiso-rrhh/permisos/calcular`. Del otro lado sale entero
/// de `PermisoDao.diasPorEmpleado`, la misma consulta que usa la simulación
/// colectiva: `dbo.f_CalcularDiasHabilesPermiso` para los días y un
/// `OUTER APPLY` con `@desde < p.hasta AND @hasta > p.desde` para el cruce.
///
/// ## Una sola verdad, y no es la del legacy
///
/// El JSF calcula estos números en Java —`WizardPermiso.calcularDiasHrsSolicitadas`
/// para el modal de permiso y `calcularHrsVacPorEmpl` para el de vacación—
/// avanzando de 30 en 30 minutos. **Esa cuenta no es la que está grabando la
/// producción**: las filas escritas por lo ya migrado llevan los números de la
/// función SQL, y las dos cifras no coinciden (un 08:00→18:00 da 1,125 con la
/// función y 1,25 con el motor Java). Reimplementar el motor acá sería una
/// tercera cifra sobre el mismo número.
///
/// Consecuencia visible y esperada: el motor del modal de permiso del legacy
/// **no mira feriados** (el de vacación sí). Para un permiso que cae en feriado
/// esta pantalla va a dar MENOS días que el ERP. Es la corrección de un bug, no
/// una regresión.
///
/// ## El radio «Horario Estándar / Continuo» no viaja acá
///
/// `f_CalcularDiasHabilesPermiso` no recibe ese parámetro: lo deduce de la hora
/// de fin (`hasta > 17:30` = continuo, tope 600 min y 60 de almuerzo; si no,
/// estándar, 480 y 30). El radio sólo mueve la ventana horaria que ofrece el
/// selector de hora — mandarlo en el cuerpo sería un campo que el servidor
/// ignora, o sea un control que miente.
class SimulacionPermisoEntity {
  /// «Días de permiso» / «Total días de vacación». Es **el mismo número que se
  /// graba**: el backend re-simula dentro de la transacción y no confía en lo
  /// que trajo el cliente.
  final double dias;

  /// «Horas de permiso» = `dias * 8`, calculado por el backend. En horario
  /// continuo un día entero da 1,25 días y 10 horas: ver [NominaPermisoEntity].
  final double horas;

  /// «Horas a reponer», **calculadas por el servidor** con la regla del legacy
  /// (`tipoPermiso in ('otro','pcr')` → las horas del permiso; si no, 0).
  ///
  /// Es un cartel, no un dato: `p_abm_Permiso` no tiene parámetro donde
  /// guardarlas y `trh_permiso` no tiene columna. Viene de allá igual porque la
  /// regla tiene que estar escrita en un solo lado — recalcularla acá era el
  /// mismo «segundo motor» que el módulo evita para los días.
  final double horasAReponer;

  /// De qué sucursal salieron los feriados que se descontaron. Va en pantalla
  /// porque explica por qué a dos personas con el mismo rango les toca
  /// distinto.
  final int codSucursal;
  final String datoSucursal;

  /// **El alta se puede guardar.** Es el `entra` de `EmpleadoColectivoDto`: el
  /// mismo campo con el que la carga colectiva decide a quién incluye, y lo
  /// resuelve el mismo método del DAO que después vuelve a correr adentro de la
  /// transacción.
  ///
  /// En `false` por cualquiera de los motivos que el servidor va a rechazar: no
  /// tiene relación laboral activa, tiene más de una, el rango no le deja ni
  /// medio día hábil, o —el que más pasa— **pisa un permiso que ya tiene
  /// cargado**. Hay 294 pares solapados en `trh_permiso` y el chequeo no existe
  /// en el legacy: sin esto la pantalla nueva agregaría filas al mismo pozo.
  final bool entra;

  /// Por qué no entra, redactado por el servidor y con el rango del permiso que
  /// choca adentro («…que se cruza con ese rango (del 17/08/2026 08:00 al…)»).
  /// Vacío cuando [entra].
  ///
  /// Se muestra tal cual: es el mismo texto con el que el DAO rechaza el alta,
  /// así que la pantalla no puede decir una cosa y el servidor otra.
  final String detalle;

  const SimulacionPermisoEntity({
    this.dias = 0,
    this.horas = 0,
    this.horasAReponer = 0,
    this.codSucursal = 0,
    this.datoSucursal = '',
    this.entra = true,
    this.detalle = '',
  });
}
