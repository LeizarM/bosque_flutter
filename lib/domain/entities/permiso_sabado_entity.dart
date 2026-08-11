// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_PermisoSabado @ACCION='L'`.
///
/// @L trae todos; @D solo los desfasados, que es lo que consume la pestania de
/// Control.
///
/// Un permiso de RR.HH. que cae en un sábado del rol.
///
/// La rotación A/B sabe a quién le toca, pero no sabe quién está de vacaciones.
/// Esta entidad es el cruce: [letraActual] es lo que dice la grilla hoy y
/// [letraQueCorresponde] lo que debería decir. Cuando no coinciden, alguien
/// figura viniendo un sábado que RR.HH. ya le dio libre.
class PermisoSabadoEntity {
  final int idSabado;
  final DateTime? fecha;
  final int idParticipante;
  final int codEmpleado;
  final String nombreRol;

  /// vac · baja · clb · libre · otro · pva · pcr · sinsuel · def
  final String tipoPermiso;

  /// V (vacación) · B (baja) · P (cualquier otro permiso).
  final String letraQueCorresponde;

  /// La que tiene la celda hoy. `(libre)` = no hay celda: ese día no le tocaba.
  final String letraActual;
  final String origen;
  final String motivo;

  const PermisoSabadoEntity({
    required this.idSabado,
    this.fecha,
    required this.idParticipante,
    required this.codEmpleado,
    required this.nombreRol,
    required this.tipoPermiso,
    required this.letraQueCorresponde,
    required this.letraActual,
    required this.origen,
    required this.motivo,
  });

  String get queDice => switch (tipoPermiso) {
    'vac' => 'vacaciones',
    'baja' => 'baja',
    'clb' => 'compensación',
    'sinsuel' => 'permiso sin sueldo',
    'def' => 'permiso por duelo',
    _ => 'permiso',
  };
}
