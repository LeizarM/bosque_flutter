// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** no hay tabla detrás. Es la proyección de
/// `trs_sp_puenteVacacion @ACCION='S'` — una fila por persona.
///
/// Lo que pasaría si se declarara ese sábado como **puente a cuenta de
/// vacación**: la empresa decide que no se trabaja y se lo cobra a la vacación
/// de cada uno.
///
/// **Es sólo la simulación.** Con `@ACCION='S'` el backend hace `RETURN` antes
/// de cualquier transacción, así que pedir esto no escribe nada. Aplicarlo es
/// otra llamada, y en el medio va la confirmación: un alta en lote que le
/// consume vacación a cuarenta personas no se aprieta a ciegas.
class PuenteVacacionEntity {
  /// `ALTA` (se le va a crear el permiso) o `SE SALTEA`.
  final String accion;
  final String nombreRol;
  final int codEmpleado;

  /// Cuánto se le descontaría de su saldo de vacación.
  ///
  /// Lo calcula `f_CalcularDiasHabilesPermiso`, la misma función con la que se
  /// mide cualquier otro permiso de la empresa — no es un número fijo. Por eso
  /// depende del horario elegido, y no de forma obvia: descuenta hasta 30 min
  /// de almuerzo a toda franja que pise 12:00–14:00 y topea el sábado en 4 h.
  final double dias;

  /// La capa que escribió la celda: `G` rotación · `P` jefe · `M` manual.
  final String origen;

  /// Por qué se saltea, cuando se saltea. Vacío si entra.
  final String detalle;

  final DateTime? fecha;
  final DateTime? permisoDesde;
  final DateTime? permisoHasta;
  final String motivo;

  /// Totales del lote. El backend los repite en cada fila, así que se leen de
  /// la primera; con la lista vacía no hay nada que totalizar.
  final int totalAlta;
  final int totalSalteados;
  final double diasTotales;

  const PuenteVacacionEntity({
    required this.accion,
    required this.nombreRol,
    required this.codEmpleado,
    required this.dias,
    required this.origen,
    required this.detalle,
    this.fecha,
    this.permisoDesde,
    this.permisoHasta,
    this.motivo = '',
    this.totalAlta = 0,
    this.totalSalteados = 0,
    this.diasTotales = 0,
  });

  /// Entra en el lote: se le va a dar de alta el permiso.
  bool get entra => accion == 'ALTA';

  /// La simulación no se pudo hacer, y [detalle] dice por qué.
  ///
  /// **Por qué el error viaja como una fila y no como una excepción.** El
  /// backend lee esta simulación con un `executeQuery()`, que exige sí o sí un
  /// conjunto de resultados: si el servidor cortara sin devolver nada, el
  /// driver tiraría «La instrucción no devolvió un conjunto de resultados» —
  /// una excepción sin traducir que en pantalla se lee como si se hubiera roto
  /// el sistema, en vez de «falta tal dato». Así el motivo llega entero.
  bool get esError => accion == 'ERROR';
}
