class PlanillaEntity {
  final int codPlanilla;
  final DateTime? fechaPeriodo;
  final DateTime? fechaEjecucion;
  final String estado;
  final int codEmpresa;
  final String empresa;
  final int codSeguro;
  final String caja;
  final double totalLiquido;

  // Paginación y utilitarios
  final int fila;
  final int totalRegistros;
  final int totalPaginas;

  PlanillaEntity({
    required this.codPlanilla,
    this.fechaPeriodo,
    this.fechaEjecucion,
    required this.estado,
    required this.codEmpresa,
    required this.empresa,
    required this.codSeguro,
    required this.caja,
    required this.totalLiquido,
    required this.fila,
    required this.totalRegistros,
    required this.totalPaginas,
  });
}
