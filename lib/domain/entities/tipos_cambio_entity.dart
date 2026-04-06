class TiposCambioEntity {
  BigInt idTipoCambio;
  int codBanco;
  DateTime fechaVigencia;
  int idMonedaOrigen;
  int idMonedaDestino;
  double tasaCompra;
  double tasaVenta;
  double tasaPromedio;
  String fuente;
  int audUsuario;

  TiposCambioEntity({
    required this.idTipoCambio,
    required this.codBanco,
    required this.fechaVigencia,
    required this.idMonedaOrigen,
    required this.idMonedaDestino,
    required this.tasaCompra,
    required this.tasaVenta,
    required this.tasaPromedio,
    required this.fuente,
    required this.audUsuario,
  });
}
