/// Nota de venta cerrada que todavia no se pago.
///
/// El listado mezcla detalle con totales. Las filas de total llegan sin
/// idNoPagado y con el nombre como "Total X" o "TOTAL PENDIENTES".
class NotaPendienteEntity {
  final int fila;
  final int? idNoPagado;
  final int? codVendedor;
  final String nombreVen;
  final DateTime? fechaDoc;
  final int? mes;
  final int? anio;
  final int? docNum;

  /// Ya viene traducido desde el SP: Valido o Anulado.
  final String valido;

  final String indicador;

  /// Ya viene traducido desde el SP: Abierta o Cerrada.
  final String estado;

  final double montoTotalBs;
  final double montoCerradoBs;
  final String origen;
  final double saldoPendiente;

  const NotaPendienteEntity({
    required this.fila,
    this.idNoPagado,
    this.codVendedor,
    required this.nombreVen,
    this.fechaDoc,
    this.mes,
    this.anio,
    this.docNum,
    required this.valido,
    required this.indicador,
    required this.estado,
    required this.montoTotalBs,
    required this.montoCerradoBs,
    required this.origen,
    required this.saldoPendiente,
  });

  /// Sin idNoPagado la fila es un total, no una nota.
  bool get esTotal => idNoPagado == null;

  /// El total general, que cierra el listado.
  bool get esTotalGeneral => esTotal && nombreVen.startsWith('TOTAL');
}
