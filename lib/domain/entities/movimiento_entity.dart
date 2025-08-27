class MovimientoEntity {
  int idMovimiento;
  String tipoMovimiento;
  int idOrigen;
  String codigoOrigen;
  int sucursalOrigen;
  int idDestino;
  String codigoDestino;
  int sucursalDestino;
  int codSucursal;
  DateTime fechaMovimiento;
  double valor;
  double valorEntrada;
  double valorSalida;
  double valorSaldo;
  String unidadMedida;
  int estado;
  String obs;
  int codEmpleado;
  int idCompraGarrafa;
  int audUsuario;

  MovimientoEntity({
    required this.idMovimiento,
    required this.tipoMovimiento,
    required this.idOrigen,
    required this.codigoOrigen,
    required this.sucursalOrigen,
    required this.idDestino,
    required this.codigoDestino,
    required this.sucursalDestino,
    required this.codSucursal,
    required this.fechaMovimiento,
    required this.valor,
    required this.valorEntrada,
    required this.valorSalida,
    required this.valorSaldo,
    required this.unidadMedida,
    required this.estado,
    required this.obs,
    required this.codEmpleado,
    required this.idCompraGarrafa,
    required this.audUsuario,
  });
}
