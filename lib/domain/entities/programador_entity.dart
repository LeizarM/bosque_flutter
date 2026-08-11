// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_Programador`, via `p_list_trs_Programador @ACCION='L'`.
///
/// `dependientes` es un COUNT sobre `fn_trs_ProgramadorDependiente()` dentro del
/// mismo @L, no una columna.
///
/// Una fila del ABM de programadores: quién tiene permiso para programar.
///
/// Sólo la toca ROLE_ADM. Es la tabla `trs_Programador` tal cual, con el nombre
/// del jefe y del reemplazo ya resueltos por el listado.
class ProgramadorEntity {
  final int idProgramador;
  final int codEmpleado;
  final String jefe;
  final int codSucursal;

  /// Nombre de la sucursal del permiso.
  ///
  /// Vacío cuando el permiso no fija sucursal, y ahí el vacío **es** la
  /// respuesta: vale para todas, no hay una que nombrar. Se muestra esto y no
  /// el código — «sucursal 20» no le dice nada a nadie.
  final String sucursal;

  /// DIRECTOS | SUBARBOL. El default para uno nuevo es DIRECTOS: dar SUBARBOL
  /// de entrada es regalar media empresa sin que nadie lo haya pedido.
  final String alcance;

  /// Quién programa cuando el titular no está. 0 = nadie.
  final int codEmpleadoReemplazo;
  final String reemplazo;

  /// 'A' activo · 'I' dado de baja. La baja es lógica: la traza de lo que ese
  /// jefe ya programó tiene que seguir existiendo.
  final String estado;

  /// Cuánta gente le cuelga hoy según el organigrama.
  final int dependientes;

  const ProgramadorEntity({
    required this.idProgramador,
    required this.codEmpleado,
    required this.jefe,
    required this.codSucursal,
    this.sucursal = '',
    required this.alcance,
    required this.codEmpleadoReemplazo,
    required this.reemplazo,
    required this.estado,
    required this.dependientes,
  });

  bool get activo => estado == 'A';
}
