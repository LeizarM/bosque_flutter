/// Una función asignada a un empleado en una sucursal (`tb_asigFunModXEmpl`).
/// Los nombres solo vienen en el listado; para un alta bastan los códigos.
class AsignacionFuncionEntity {
  final BigInt codAsignacion;
  final int codFuncMod;
  final String funcion;
  final int codModulo;
  final String modulo;
  final int codEmpleado;
  final String empleado;
  final int codSucursal;
  final String sucursal;
  final String empresa;
  final bool activo;

  const AsignacionFuncionEntity({
    required this.codAsignacion,
    required this.codFuncMod,
    required this.codEmpleado,
    required this.codSucursal,
    this.funcion = '',
    this.codModulo = 0,
    this.modulo = '',
    this.empleado = '',
    this.sucursal = '',
    this.empresa = '',
    this.activo = true,
  });
}
