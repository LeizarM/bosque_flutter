class BancoEntity {
  final int codBanco;
  final String nombre;
  final int audUsuario;
  final int fila;

  /// Uso del banco. Solo los trae la lista de la pantalla (`p_list_Banco` 'P');
  /// en los combos quedan en 0.
  final int cheques;
  final int cuentasEmpresa;
  final int cuentasEmpleados;
  final int movimientos;
  final int pagosExterior;

  BancoEntity({
    required this.codBanco,
    required this.nombre,
    required this.audUsuario,
    required this.fila,
    this.cheques = 0,
    this.cuentasEmpresa = 0,
    this.cuentasEmpleados = 0,
    this.movimientos = 0,
    this.pagosExterior = 0,
  });

  /// Cuentas de la empresa más cuentas de sueldo vigentes.
  int get cuentas => cuentasEmpresa + cuentasEmpleados;

  /// Tiene algo que lo referencia: cheques, cuentas o movimientos.
  bool get enUso => cheques + cuentas + movimientos + pagosExterior > 0;
}
