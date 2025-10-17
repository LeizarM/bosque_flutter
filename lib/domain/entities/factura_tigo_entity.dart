class FacturaTigoEntity {
  final int codFactura;
  final String nroFactura;
  final String tipoServicio;
  final String nroContrato;
  final String nroCuenta;
  final String periodoCobrado;
  final String descripcionPlan;
  final double totalCobradoXCuenta;
  final String? estado;
  final int audUsuario;
  FacturaTigoEntity({
    required this.codFactura,
    required this.nroFactura,
    required this.tipoServicio,
    required this.nroContrato,
    required this.nroCuenta,
    required this.periodoCobrado,
    required this.descripcionPlan,
    required this.totalCobradoXCuenta,
    required this.estado,
    required this.audUsuario,
  });
}