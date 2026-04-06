class CargoPagoEntity {
  BigInt idCargo;
  BigInt idCotizacion;
  BigInt idTransaccion;
  BigInt idTipoCargo;
  double baseCalculo;
  String origenBase;
  double porcentaje;
  double valorFijo;
  double montoCargo;
  int idMoneda;
  int orden;
  String descripcion;
  int audUsuario;

  CargoPagoEntity({
    required this.idCargo,
    required this.idCotizacion,
    required this.idTransaccion,
    required this.idTipoCargo,
    required this.baseCalculo,
    required this.origenBase,
    required this.porcentaje,
    required this.valorFijo,
    required this.montoCargo,
    required this.idMoneda,
    required this.orden,
    required this.descripcion,
    required this.audUsuario,
  });
}
