/// Un segmento de tiempo del reporte: qué ganó esa parte de la jornada (una
/// comida, la doble, una hora con su recargo o nada) y cómo se paga, en
/// palabras del SP. La app solo lo dibuja; no hace cuentas.
class HexReporteTramoEntity {
  final int orden;
  final DateTime? desde;
  final DateTime? hasta;

  /// `HH:mm`, como lo arma el SP.
  final String horaDesde;
  final String horaHasta;
  final int minutos;

  /// «1 h», «30 min», «1 h 15 min».
  final String duracionTexto;

  /// `COMIDA`, `HORA` o `SIN_PAGO`.
  final String clase;
  final String? codigo;
  final String? leyenda;
  final String textoPago;

  /// Bs del segmento: solo lo trae el simulador; el reporte (D36) no.
  final double? monto;

  /// El mismo en todas las filas: «2 h 30 min en total (…)».
  final String? resumen;

  const HexReporteTramoEntity({
    this.orden = 0,
    this.desde,
    this.hasta,
    this.horaDesde = '',
    this.horaHasta = '',
    this.minutos = 0,
    this.duracionTexto = '',
    this.clase = '',
    this.codigo,
    this.leyenda,
    this.textoPago = '',
    this.monto,
    this.resumen,
  });
}
