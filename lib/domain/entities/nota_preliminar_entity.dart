/// Una nota (factura) que compone una fila del preliminar.
///
/// Es el desglose que en Bosque v2 abria el boton «Ver Notas a Pagar»: las
/// facturas cerradas y sin pagar de ese vendedor, en ese periodo, cuya
/// diferencia de dias las dejo en ese tramo de comision. La suma de
/// [montoCerradoBs] de las notas reales es el «Monto base» de la fila.
class NotaPreliminarEntity {
  const NotaPreliminarEntity({
    required this.idVendedor,
    required this.nombreVen,
    this.fechaDoc,
    this.mes,
    this.anio,
    required this.docNum,
    this.valido,
    this.indicador,
    this.estado,
    required this.montoCerradoBs,
    this.origen,
    this.tc,
    this.fechaUltimoPago,
    this.diferenciaDias,
  });

  final int idVendedor;
  final String nombreVen;

  /// Fecha de la factura.
  final DateTime? fechaDoc;

  final int? mes;
  final int? anio;

  /// Numero de documento en SAP. En la fila de total llega en 0.
  final int docNum;

  /// Valido o Anulada, ya traducido por el SP.
  final String? valido;

  final String? indicador;

  /// Abierta o Cerrada, ya traducido por el SP.
  final String? estado;

  /// Monto de la venta cerrada, en bolivianos.
  final double montoCerradoBs;

  /// Sistema del que viene: IMPEXPAP, ESPPAPEL, PRODUCTIVA PAPEL.
  final String? origen;

  final double? tc;

  /// Fecha del ultimo cobro.
  final DateTime? fechaUltimoPago;

  /// Dias entre la factura y el cobro. Es lo que define el tramo, o sea el
  /// porcentaje que termina pagandose.
  final int? diferenciaDias;

  /// La fila de cierre que agrega el SP, no una nota.
  ///
  /// Se detecta por [docNum] en 0: el total es la unica fila sin documento.
  bool get esTotal => docNum == 0;

  /// La nota fue anulada. Se muestra distinto porque suma 0 al monto base.
  bool get anulada =>
      valido != null && valido!.toLowerCase().startsWith('anul');
}
