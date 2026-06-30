class PlanillaDetalleEntity {
  final int codPlanilla;
  final int codEmpleado;
  final String ciNumero;
  final String apellidos;
  final String nombres;
  final String nombreCompleto;
  final String nacionalidad;
  final DateTime? fechaNacimiento;
  final String sexo;
  final String cargo;
  final DateTime? fechaIngreso;
  final DateTime? fechaSalida;
  final double diasPagadosMes;
  final double horasDiasPagadas;
  final double haberBasico;
  final double bonoAntiguedad;
  final double bonoProduccion;
  final double total;
  final double afp;
  final double saldoPrestamo;
  final double cuotasDolares;
  final double cuotasBolivianos;
  final double multas;
  final double anticipo;
  final double otros;
  final double totalDescuentos;
  final double liquido;

  final double totalHaberBasico;
  final double totalBonoAntiguedad;
  final double totalBonoProduccion;
  final double sumTotalGanado;
  final double totalAFP;
  final double totalSaldoPrestamo;
  final double totalCuotasDolares;
  final double totalCuotasBolivianos;
  final double totalMultas;
  final double totalAnticipo;
  final double totalOtros;
  final double totalTotalDescuentos;
  final double totalLiquido;

  // Paginación y utilitarios
  final int fila;
  final int totalRegistros;
  final int totalPaginas;

  // Validación de negocio (desde BD)
  final bool tieneError;
  final String? mensajeError;

  PlanillaDetalleEntity({
    required this.codPlanilla,
    required this.codEmpleado,
    required this.ciNumero,
    required this.apellidos,
    required this.nombres,
    required this.nombreCompleto,
    required this.nacionalidad,
    this.fechaNacimiento,
    required this.sexo,
    required this.cargo,
    this.fechaIngreso,
    this.fechaSalida,
    required this.diasPagadosMes,
    required this.horasDiasPagadas,
    required this.haberBasico,
    required this.bonoAntiguedad,
    required this.bonoProduccion,
    required this.total,
    required this.afp,
    required this.saldoPrestamo,
    required this.cuotasDolares,
    required this.cuotasBolivianos,
    required this.multas,
    required this.anticipo,
    required this.otros,
    required this.totalDescuentos,
    required this.liquido,
    required this.totalHaberBasico,
    required this.totalBonoAntiguedad,
    required this.totalBonoProduccion,
    required this.sumTotalGanado,
    required this.totalAFP,
    required this.totalSaldoPrestamo,
    required this.totalCuotasDolares,
    required this.totalCuotasBolivianos,
    required this.totalMultas,
    required this.totalAnticipo,
    required this.totalOtros,
    required this.totalTotalDescuentos,
    required this.totalLiquido,
    required this.fila,
    required this.totalRegistros,
    required this.totalPaginas,
    this.tieneError = false,
    this.mensajeError,
  });
}
