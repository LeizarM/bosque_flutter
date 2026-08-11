// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Rol @ACCION='I'`.
///
/// Unifica las cuatro formas de salirse del default: evento, programacion,
/// cambio y correccion manual.
///
/// Una intervención humana sobre el horario por defecto, venga de donde venga.
///
/// **Pocas filas = el default está bien calibrado.** Muchas = alguna regla no
/// representa cómo se trabaja de verdad, y conviene arreglar la regla en vez de
/// seguir corrigiendo a mano.
class IntervencionEntity {
  final int idRol;
  final int idSabado;
  final DateTime? fechaSabado;

  /// PROGRAMACION · CAMBIO · CONVOCATORIA:CONVOCADO · CONVOCATORIA:EXCUSADO ·
  /// CORRECCION MANUAL.
  final String tipoIntervencion;
  final int codEmpleado;
  final String nombreRol;
  final String quedoEn;
  final int loHizo;
  final DateTime? cuando;
  final int diasAntelacion;
  final String motivo;

  const IntervencionEntity({
    required this.idRol,
    required this.idSabado,
    this.fechaSabado,
    required this.tipoIntervencion,
    required this.codEmpleado,
    required this.nombreRol,
    required this.quedoEn,
    required this.loHizo,
    this.cuando,
    required this.diasAntelacion,
    required this.motivo,
  });
}
