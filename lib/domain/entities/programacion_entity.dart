// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_Programacion`, via `p_list_trs_Programacion @ACCION='L'`.
///
/// `celdasAfectadas` y `controlAntelacion` son calculados dentro del @L, no
/// columnas de la tabla.
///
/// Un jefe le cambió el sábado a un dependiente.
class ProgramacionEntity {
  final int idProgramacion;
  final int idRol;
  final int idSabado;
  final DateTime? sabado;
  final int codEmpleadoProgramador;
  final int codEmpleadoEjecutor;
  final DateTime? fechaProgramacion;

  /// Días entre el aviso y el sábado. Es el dato que importa: avisar el viernes
  /// no es lo mismo que avisar con un mes.
  final int diasAntelacion;
  final String controlAntelacion;
  final String estado;
  final String motivo;
  final int celdasAfectadas;

  const ProgramacionEntity({
    required this.idProgramacion,
    required this.idRol,
    required this.idSabado,
    this.sabado,
    required this.codEmpleadoProgramador,
    required this.codEmpleadoEjecutor,
    this.fechaProgramacion,
    required this.diasAntelacion,
    required this.controlAntelacion,
    required this.estado,
    required this.motivo,
    required this.celdasAfectadas,
  });

  bool get vigente => estado == 'VIGENTE';
  bool get avisoTardio => controlAntelacion.contains('TARDIO');
}
