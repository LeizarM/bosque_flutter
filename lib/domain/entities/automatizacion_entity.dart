// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Asignacion @ACCION='A'`.
///
/// **Devuelve UNA sola fila**, por eso el repositorio usa `postAndReturnObject`
/// y no `postAndReturnList`.
///
/// Los contadores son `Integer` y no `int` a proposito: un SUM sobre cero filas
/// devuelve NULL, no 0.
///
/// Cuánto del rol lo resuelve el sistema solo.
class AutomatizacionEntity {
  final int celdasTotales;
  final int conDecisionHumana;
  final int generadasSolas;

  const AutomatizacionEntity({
    required this.celdasTotales,
    required this.conDecisionHumana,
    required this.generadasSolas,
  });

  /// Porcentaje de celdas que nadie tuvo que tocar.
  double get porcentajeAutomatico =>
      celdasTotales == 0 ? 0 : generadasSolas * 100 / celdasTotales;
}
