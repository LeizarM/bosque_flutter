// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "rrhh" a secas ya nombra otro modulo entero.

/// **Origen:** tabla `dbo.trs_Rrhh`, via `p_list_trs_Rrhh @ACCION='L'`.
///
/// Alguien que puede corregir **cualquier** celda del rol de sábados.
///
/// **Por qué esto es una tabla y no un rol de usuario.** Escribir una celda a
/// mano no tenía dueño: bastaba con estar logueado, así que cualquiera de los
/// usuarios `ROLE_LIM` podía cambiarle el sábado a cualquier persona y firmarlo
/// con el `audUsuario` que quisiera. El rol de Spring no servía para taparlo:
/// `ROLE_ADM` son los de Sistemas y `ROLE_LIM` son todos los demás. La gente que
/// de verdad carga vacaciones y bajas no se distingue por su rol de usuario, así
/// que hay que nombrarla.
///
/// **No confundir con [ProgramadorEntity]**, que es la otra mitad del control:
/// un jefe programador tiene un árbol y una sucursal y sólo alcanza a su propia
/// gente, y sólo puede decidir si viene o no viene. Quien está acá no tiene
/// límite de árbol, de sucursal ni de letra.
class RrhhSabadosEntity {
  final int idRrhh;
  final int codEmpleado;

  /// Apellido y nombres, ya armados por el backend.
  final String persona;

  /// Cargo y sucursal **vigentes**. Pueden llegar vacíos: alguien sin cargo
  /// cargado tiene que seguir apareciendo en el padrón, no desaparecer.
  final String cargo;
  final String sucursal;

  /// `A` = puede corregir · `I` = ya no.
  final String estado;
  final String observacion;
  final DateTime? audFecha;

  const RrhhSabadosEntity({
    required this.idRrhh,
    required this.codEmpleado,
    required this.persona,
    required this.cargo,
    required this.sucursal,
    required this.estado,
    required this.observacion,
    this.audFecha,
  });

  bool get activo => estado == 'A';
}
