/// Planilla de horas extra ejecutada para una empresa, sucursal y mes, con sus
/// totales y, si se anuló, quién y por qué.
class HexPlanillaEntity {
  final BigInt? idPlanilla;
  final BigInt? codEmpresa;
  final int anio;
  final int mes;
  final String periodoTexto;
  final BigInt? codSucursal;
  final String? nombreSucursal;

  /// `EJECUTADA` o `ANULADA`.
  final String estado;
  final String estadoTexto;
  final DateTime? fechaEjecucion;
  final BigInt? codEmpleadoEjecutor;
  final String nombreEjecutor;
  final double totalHoras;
  final double totalComidas;
  final double total;
  final int cantidadEmpleados;
  final int cantidadReportes;
  final String? motivoAnulacion;
  final DateTime? fechaAnulacion;
  final BigInt? codEmpleadoAnulador;
  final String? nombreAnulador;

  /// D39: el lote del mes con que se ejecutó; nulo si se ejecutó sola.
  final BigInt? idLote;

  const HexPlanillaEntity({
    this.idPlanilla,
    this.codEmpresa,
    this.anio = 0,
    this.mes = 0,
    this.periodoTexto = '',
    this.codSucursal,
    this.nombreSucursal,
    this.estado = '',
    this.estadoTexto = '',
    this.fechaEjecucion,
    this.codEmpleadoEjecutor,
    this.nombreEjecutor = '',
    this.totalHoras = 0,
    this.totalComidas = 0,
    this.total = 0,
    this.cantidadEmpleados = 0,
    this.cantidadReportes = 0,
    this.motivoAnulacion,
    this.fechaAnulacion,
    this.codEmpleadoAnulador,
    this.nombreAnulador,
    this.idLote,
  });
}
