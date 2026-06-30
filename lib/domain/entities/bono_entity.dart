class BonoEntity {
  final int codBono;
  final DateTime? fechaCreacion;
  final String descripcion;
  final String estado;
  final DateTime? fechaEjecucion;
  final String tipoBono;
  final double montoTotal;
  final int audUsuarioI;

  // Paginación y utilitarios
  final int fila;
  final int totalRegistros;
  final int totalPaginas;

  BonoEntity({
    required this.codBono,
    this.fechaCreacion,
    required this.descripcion,
    required this.estado,
    this.fechaEjecucion,
    required this.tipoBono,
    required this.montoTotal,
    required this.audUsuarioI,
    required this.fila,
    required this.totalRegistros,
    required this.totalPaginas,
  });
}
