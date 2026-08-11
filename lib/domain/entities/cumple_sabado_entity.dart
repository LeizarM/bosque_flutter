// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Participante @ACCION='K'`.
///
/// `situacionAsueto` dice si el asueto se aplico, si no correspondia, o si
/// quedo pisado por otra cosa.
///
/// Cumpleaños que cae sábado, y qué pasó con el asueto.
class CumpleSabadoEntity {
  final int idParticipante;
  final int codEmpleado;
  final String nombreRol;
  final DateTime? fechaNacimiento;
  final int idSabado;
  final DateTime? fechaSabado;
  final String estadoActual;

  /// ASUETO · ASUETO ANULADO POR EVENTO · LO EXCUSARON · DECIDIO VENIR ·
  /// FERIADO. Es la lista que RR.HH. necesita para saber a quién compensar.
  final String situacionAsueto;
  final String motivoEspecial;

  const CumpleSabadoEntity({
    required this.idParticipante,
    required this.codEmpleado,
    required this.nombreRol,
    this.fechaNacimiento,
    required this.idSabado,
    this.fechaSabado,
    required this.estadoActual,
    required this.situacionAsueto,
    required this.motivoEspecial,
  });
}
