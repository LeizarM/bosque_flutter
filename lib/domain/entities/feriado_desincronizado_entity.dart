// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Sabado @ACCION='F'`.
///
/// Compara `trs_Sabado.esFeriado` contra `trh_diaNoLaborable`.
///
/// `quePasa` ya viene redactado por el SP: se muestra tal cual.
///
/// Un sábado cuya marca de feriado no coincide con lo que dice RR.HH. hoy.
class FeriadoDesincronizadoEntity {
  final int idSabado;
  final int idRol;
  final String rol;
  final DateTime? fecha;

  /// El `esFeriado` que quedó grabado en el rol.
  final int marcadoEnElRol;

  /// Lo que dice `trh_diaNoLaborable` AHORA.
  final int aplicaEnRRHH;
  final String motivo;

  /// FALTA APLICAR · FALTA QUITAR · PUNTERO VIEJO.
  final String quePasa;
  final int personasQueHoyFiguranTrabajando;

  const FeriadoDesincronizadoEntity({
    required this.idSabado,
    required this.idRol,
    required this.rol,
    this.fecha,
    required this.marcadoEnElRol,
    required this.aplicaEnRRHH,
    required this.motivo,
    required this.quePasa,
    required this.personasQueHoyFiguranTrabajando,
  });
}
