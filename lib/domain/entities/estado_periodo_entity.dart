/// Estado de ejecucion de un periodo de comisiones.
class EstadoPeriodoEntity {
  final int mes;
  final int anio;

  /// 1 vendedores internos, 0 externos.
  final int esInterno;

  final int ejecutado;
  final int cantidadPagados;
  final DateTime? fechaEjecucion;
  final double totalComision;

  const EstadoPeriodoEntity({
    required this.mes,
    required this.anio,
    required this.esInterno,
    required this.ejecutado,
    required this.cantidadPagados,
    this.fechaEjecucion,
    required this.totalComision,
  });

  /// Un periodo ejecutado no se puede volver a cargar ni a pagar.
  bool get yaEjecutado => ejecutado == 1;

  bool get esInternos => esInterno == 1;

  String get periodo => '${mes.toString().padLeft(2, '0')}/$anio';
}
