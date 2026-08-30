/// Nombres de botón del módulo de Talonarios, tal como están en `tb_vistaBtn`.
///
/// **De dónde salen.** Los cuatro ya existían en la BD antes de esta migración
/// y los tienen 134 usuarios asignados. Están registrados bajo la vista 62
/// (`tfmFacturasManuales/talonario`), que es el listado read-only del módulo
/// de facturas manuales.
///
/// **Por qué se reutilizan igual.** El chequeo de permisos es por NOMBRE de
/// botón, no por vista: `p_list_UsuarioBtn @ACCION='A'` devuelve la lista plana
/// de `nombreBtn` del usuario, y `tienePermiso(nombreBtn)` la consulta sin
/// mirar de qué vista viene. Semánticamente son los correctos y el padrón de
/// 134 usuarios ya es el de quienes administran talonarios.
///
/// **Lo que falta.** La vista 91 (`tmtoTalonario/talonario`, el wizard que se
/// está migrando) **no tiene ni un botón definido**: el JSF solo la protegía
/// con `tieneSesionActiva()`. Si se quiere control separado para las pantallas
/// nuevas hay que dar de alta filas en `tb_vistaBtn` para la vista 91 y
/// asignarlas en `tb_usuarioBtn`; hasta entonces estas cuatro son las únicas
/// que existen.
///
/// Nota: `ROLE_ADM` pasa siempre, aun mientras los permisos están cargando.
class TalonariosBotones {
  const TalonariosBotones._();

  /// Alta de talonario.
  static const String nuevo = 'btnTalonNewTal';

  /// Edición del talonario. Se usa además para las transiciones de estado
  /// (devolver, cerrar), que no tienen botón propio en la BD.
  static const String editar = 'btnTalonEditTal';

  /// Baja de talonario.
  static const String eliminar = 'btnTalonElimTal';

  /// Reporte por talonario.
  static const String reporte = 'btnFmTalRptPorTal';
}
