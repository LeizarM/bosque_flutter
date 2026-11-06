/// Un segmento de la jornada simulada: las mismas columnas que el reporte por
/// tramos (D36) más el factor y el monto en Bs que salen del SP.
class HexSimulacionSegmentoEntity {
  final int orden;
  final DateTime? desde;
  final DateTime? hasta;
  final String horaDesde;
  final String horaHasta;
  final int minutos;
  final String duracionTexto;

  /// `HORA`, `COMIDA` o `SIN_PAGO`.
  final String clase;
  final String? codigo;
  final String? leyenda;
  final double? multiplicador;
  final double monto;
  final String textoPago;
  final String? resumen;

  const HexSimulacionSegmentoEntity({
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
    this.multiplicador,
    this.monto = 0,
    this.textoPago = '',
    this.resumen,
  });
}
