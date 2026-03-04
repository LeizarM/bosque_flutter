class DetalleSolicitudEntity {
  BigInt idDetalle;
  BigInt idSolicitudProveedor;
  String tipoDocumento;
  String numeroDocumento;
  int facturaProvSap;
  String codigoImportacion;
  double montoFacturaUsd;
  double montoAmortizadoUsd;
  double montoAPagarUsd;
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
    required this.montoFacturaUsd,
    required this.montoAmortizadoUsd,
    required this.montoAPagarUsd,
    required this.fechaFactura,
    required this.fechaVencimiento,
    required this.concepto,
    required this.obs,
    required this.esAprobado,
    required this.audUsuario,
    required this.codEmpresa,
  });
}
