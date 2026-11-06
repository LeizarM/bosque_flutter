/// Un encargado que se puede elegir al asignar un jefe de área (D35). Lo
/// calcula `p_list_thex_Aprobador` E; la app solo lo muestra.
class HexEncargadoOpcionEntity {
  final BigInt? codEmpleado;
  final String nombreEmpleado;
  final String? cargo;

  /// Empleados activos de su rama hoy, contados por el SP.
  final int cantidadRama;

  /// Los jefes que ya lo aprueban, separados por coma; nulo si ninguno.
  final String? jefesActuales;

  const HexEncargadoOpcionEntity({
    this.codEmpleado,
    this.nombreEmpleado = '',
    this.cargo,
    this.cantidadRama = 0,
    this.jefesActuales,
  });
}
