/// Línea del desglose de un reporte: un tramo de horas o una comida, con su
/// cantidad, valor unitario y monto.
class HexReporteLineaEntity {
  final BigInt? idReporte;

  /// `TRAMO` o `COMIDA`.
  final String concepto;
  final String codigo;
  final String leyenda;
  final int? minutos;
  final double cantidad;
  final double? multiplicador;

  /// Nulos en la vista del encargado (D38): no ve dinero.
  final double? valorUnitario;
  final double? monto;

  const HexReporteLineaEntity({
    this.idReporte,
    this.concepto = '',
    this.codigo = '',
    this.leyenda = '',
    this.minutos,
    this.cantidad = 0,
    this.multiplicador,
    this.valorUnitario,
    this.monto,
  });
}
