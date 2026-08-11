// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** no hay tabla detras. Es la proyeccion de
/// `p_list_trs_Programador @ACCION='D'`.
///
/// El organigrama expandido en forma recursiva.
///
/// Se llama ProgramadorDependiente y no Dependiente porque `DependienteEntity`
/// ya existe y es otra cosa: los familiares en ficha-trabajador.
///
/// Alguien a quien puedo mover el sábado.
///
/// La lista no se arma a mano: sale del organigrama, así que cuando RR.HH.
/// cambia a alguien de jefe el equipo se corrige solo, sin que nadie tenga que
/// acordarse de venir acá a mantenerlo.
class ProgramadorDependienteEntity {
  final int idProgramador;

  /// El `codEmpleado` del jefe titular — el dueño del permiso, que no siempre
  /// es quien está mirando la pantalla (puede ser su reemplazo).
  final int codProgramador;

  /// Cuántos escalones hay entre el jefe y esta persona. 1 = le reporta directo.
  final int profundidad;
  final int codDependiente;
  final String nombreDependiente;
  final int sucDependiente;

  /// El nombre de la sucursal, ya resuelto. **Sólo lo trae `@ACCION='P'`**
  /// (la previsualización); con `'D'` llega vacío.
  final String sucursal;

  /// 1 si además es participante activo del rol. **Sólo lo trae `@ACCION='P'`.**
  ///
  /// Estar en el organigrama no alcanza para que el jefe pueda moverle el
  /// sábado: `trs_sp_programar` exige las dos cosas. Alguien con `enElRol = 0`
  /// le va a aparecer al jefe con el cartel «no está en el rol de este año».
  final int enElRol;

  const ProgramadorDependienteEntity({
    required this.idProgramador,
    required this.codProgramador,
    required this.profundidad,
    required this.codDependiente,
    required this.nombreDependiente,
    required this.sucDependiente,
    this.sucursal = '',
    this.enElRol = 0,
  });

  /// Le reporta directo. Con alcance DIRECTOS son todos; con SUBARBOL sirve
  /// para separar a los propios de los que cuelgan más abajo.
  bool get esDirecto => profundidad == 1;

  /// Participa del rol, así que el jefe va a poder moverle el sábado.
  bool get participaDelRol => enElRol == 1;
}
