class BonoEmpleadoEntity {
  final int codBonEmp;
  final int codBono;
  final int codEmpleado;
  final double monto;
  final int audUsuarioI;

  final String nombreCompleto;

  // Paginación y utilitarios
  final int fila;
  final int totalRegistros;
  final int totalPaginas;

  BonoEmpleadoEntity({
    required this.codBonEmp,
    required this.codBono,
    required this.codEmpleado,
    required this.monto,
    required this.audUsuarioI,
    required this.nombreCompleto,
    required this.fila,
    required this.totalRegistros,
    required this.totalPaginas,
  });
}
