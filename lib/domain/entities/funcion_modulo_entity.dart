/// Una función de un módulo (`tb_funcionesXModulo`): el rol que cumple un
/// empleado en Cheques o en Precios. [asignaciones] solo viene en el listado.
class FuncionModuloEntity {
  final BigInt codFuncMod;
  final int codModulo;
  final String modulo;
  final String funcion;
  final String detalle;
  final bool requerido;
  final bool activo;
  final int asignaciones;

  const FuncionModuloEntity({
    required this.codFuncMod,
    required this.codModulo,
    required this.funcion,
    this.modulo = '',
    this.detalle = '',
    this.requerido = false,
    this.activo = true,
    this.asignaciones = 0,
  });
}
