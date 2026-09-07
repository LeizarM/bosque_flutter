class PrestamoEntity {
  final int codEmpresa;
  final String db;
  final String codigoCuenta;
  final String nombreCuenta;
  final DateTime fechaAsiento;
  final String numAsiento;
  final String concepto;
  final String referencia;
  final String? observacion;
  final double debe;
  final double haber;
  final String estadoAsignacion;
  final String? estadoPrestamo;
  final int? codPrestamo;
  final int? codEmpleado;
  final String? nombreEmpleadoAsignado;
  final double? saldoPendiente;
  final double? numCuotas;
  final double? cuotaReferencia;
  final double? montoCuota; // Calculado por SQL
  final String? fecIniPago;
  final String? tipoPago;
  final String? tipoCalculo;

  // Campos originales del préstamo para pagos
  final double? montoOriginalPrestamo;
  final String? fechaDesembolsoOriginal;
  final String? conceptoOriginal;

  // Params Auxiliares
  final int? fila;
  final int? pagina;
  final int? tamanoPagina;
  final int? totalPaginas;
  final String? search;
  final int? totalRegistros;
  final String? fechaDesde;
  final String? fechaHasta;
  final int? mostrarAnulados;
  final int? forzar;
  final String? xmlCuotas;

  PrestamoEntity({
    required this.codEmpresa,
    required this.db,
    required this.codigoCuenta,
    required this.nombreCuenta,
    required this.fechaAsiento,
    required this.numAsiento,
    required this.concepto,
    required this.referencia,
    this.observacion,
    required this.debe,
    required this.haber,
    required this.estadoAsignacion,
    this.estadoPrestamo,
    this.codPrestamo,
    this.codEmpleado,
    this.nombreEmpleadoAsignado,
    this.saldoPendiente,
    this.numCuotas,
    this.cuotaReferencia,
    this.montoCuota,
    this.fecIniPago,
    this.tipoPago,
    this.tipoCalculo,
    this.montoOriginalPrestamo,
    this.fechaDesembolsoOriginal,
    this.conceptoOriginal,
    this.fila,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.search,
    this.totalRegistros,
    this.fechaDesde,
    this.fechaHasta,
    this.mostrarAnulados,
    this.forzar,
    this.xmlCuotas,
  });
}
