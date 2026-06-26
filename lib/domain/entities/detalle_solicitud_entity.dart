class DetalleSolicitudEntity {
  BigInt idDetalle;
  BigInt idSolicitudProveedor;
  String tipoDocumento;
  String numeroDocumento;
  int facturaProvSap;
  String codigoImportacion;
  int numeroCuota; // 1, 2, 3... permite múltiples cuotas por mismo facturaProvSap
  double montoFacturaUsd;
  double montoAmortizadoUsd;
  double montoAPagarUsd; // monto de esta cuota
  double montoTotalDocumento; // total del documento SAP (DocTotal de OPCH/OPOR)
  DateTime fechaFactura;
  DateTime fechaVencimiento;
  String concepto;
  String obs;
  int esAprobado;
  int audUsuario;

  int codEmpresa;

  DetalleSolicitudEntity({
    required this.idDetalle,
    required this.idSolicitudProveedor,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.facturaProvSap,
    required this.codigoImportacion,
    this.numeroCuota = 1,
    required this.montoFacturaUsd,
    required this.montoAmortizadoUsd,
    required this.montoAPagarUsd,
    this.montoTotalDocumento = 0.0,
    required this.fechaFactura,
    required this.fechaVencimiento,
    required this.concepto,
    required this.obs,
    required this.esAprobado,
    required this.audUsuario,
    required this.codEmpresa,
  });
}
