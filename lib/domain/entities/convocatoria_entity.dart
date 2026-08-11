// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_Convocatoria`, via `p_list_trs_Convocatoria @ACCION='L'`.
///
/// @L es la lista cruda. `situacion`, `celdaFinal`, `leTocabaPorRotacion`,
/// `grupoRotacion`, `nombreRol` y `codEmpleado` los aporta @D, que contrasta la
/// convocatoria contra la rotacion. En @L esos campos quedan vacios.
///
/// Una fila de la lista nominal de un evento.
class ConvocatoriaEntity {
  final int idConvocatoria;
  final int idRol;
  final int idSabado;
  final int idParticipante;
  final int codEmpleado;
  final String nombreRol;
  final String grupoRotacion;

  /// CONVOCADO (viene aunque no le toque) | EXCUSADO (no viene aunque le toque).
  final String tipo;
  final String motivo;

  /// 1 = ya venía por rotación. Un CONVOCADO con 1 no agrega a nadie.
  final int leTocabaPorRotacion;
  final String celdaFinal;
  final String situacion;

  const ConvocatoriaEntity({
    required this.idConvocatoria,
    required this.idRol,
    required this.idSabado,
    required this.idParticipante,
    required this.codEmpleado,
    required this.nombreRol,
    required this.grupoRotacion,
    required this.tipo,
    required this.motivo,
    required this.leTocabaPorRotacion,
    required this.celdaFinal,
    required this.situacion,
  });

  bool get redundante => tipo == 'CONVOCADO' && leTocabaPorRotacion == 1;
}
