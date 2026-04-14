class DescuentoEmpleadoEntity {
  final int codEmpleado;
  final String descripcion;
  final String moneda;
  final double montoTotal;
  final int totalCuotas;
  final String periodo;
  final String tipoDescuento;
  final String estadoDescuento;
  final int primeraCuotaMes;
  final int ultimaCuotaMes;
  final double montoDescuento;
  final double saldoRestante;

  const DescuentoEmpleadoEntity({
    required this.codEmpleado,
    required this.descripcion,
    required this.moneda,
    required this.montoTotal,
    required this.totalCuotas,
    required this.periodo,
    required this.tipoDescuento,
    required this.estadoDescuento,
    required this.primeraCuotaMes,
    required this.ultimaCuotaMes,
    required this.montoDescuento,
    required this.saldoRestante,
  });
}
