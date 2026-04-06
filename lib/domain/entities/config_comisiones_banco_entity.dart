class ConfigComisionesBancoEntity {
  BigInt idConfig;
  int codBanco;
  BigInt idTipoTransaccion;
  BigInt idTipoCargo;
  double valorPorcentaje;
  double valorFijo;
  int idMoneda;
  int orden;
  String baseCalculo;
  int activo;
  DateTime fechaVigenciaDesde;
  DateTime fechaVigenciaHasta;
  int audUsuario;

  ConfigComisionesBancoEntity({
    required this.idConfig,
    required this.codBanco,
    required this.idTipoTransaccion,
    required this.idTipoCargo,
    required this.valorPorcentaje,
    required this.valorFijo,
    required this.idMoneda,
    required this.orden,
    required this.baseCalculo,
    required this.activo,
    required this.fechaVigenciaDesde,
    required this.fechaVigenciaHasta,
    required this.audUsuario,
  });
}
