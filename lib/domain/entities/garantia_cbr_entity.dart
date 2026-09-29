/// Garantia de cobranza de un cliente SAP (tabla tcbr_garantia).
///
/// Espeja la fila tal cual: las 12 columnas, ninguna calculada. Lo que el
/// backend resuelve por JOIN o calcula (nombre del cliente, estado, dias para
/// vencer, linea SAP) vive en [GarantiaVistaEntity], que envuelve a esta.
///
/// **El estado no es una columna.** VIGENTE / CADUCADO / CERRADO se calcula en
/// cada lectura con las fechas y con la existencia de una accion de cierre
/// (CER); por eso no aparece aca.
///
/// Los montos son `DECIMAL(15,4)` en la base y `BigDecimal` en Java. Dart no
/// tiene decimal: viajan en double y se redondean a dos decimales al mostrar.
class GarantiaCbrEntity {
  /// PK, IDENTITY. Cero en una garantia que todavia no se guardo.
  final BigInt codGarantia;

  /// CardCode del cliente en SAP. No cambia despues del alta.
  final String codClienteSAP;

  /// Valor de la garantia entregada por el cliente.
  final double montoGarantia;

  /// Linea de credito aprobada contra esta garantia.
  final double montoCredito;

  /// Plazo de pago en dias.
  final int tiempoPago;

  final DateTime? fechaInicio;
  final DateTime? fechaExpiracion;

  /// Suma de los montos de sus detalles. La calcula el backend en cada alta y
  /// cambio de detalle; la pantalla la muestra, no la edita.
  final double? montoGarantiaCalc;

  /// Reconocimiento de firmas (texto libre, hasta 30).
  final String? recFirmas;

  /// Numero de protesta (texto libre, hasta 30).
  final String? nroProtesta;

  /// Quien la grabo por ultima vez. Solo lectura: el backend lo toma del token.
  final int audUsuario;
  final DateTime? audFecha;

  const GarantiaCbrEntity({
    required this.codGarantia,
    required this.codClienteSAP,
    required this.montoGarantia,
    required this.montoCredito,
    required this.tiempoPago,
    required this.fechaInicio,
    required this.fechaExpiracion,
    required this.montoGarantiaCalc,
    required this.recFirmas,
    required this.nroProtesta,
    required this.audUsuario,
    required this.audFecha,
  });

  bool get esNueva => codGarantia == BigInt.zero;

  /// Los detalles no suman lo mismo que el valor declarado. El legacy lo
  /// marcaba con un icono de prohibido junto al monto.
  bool get difiereDeDetalles =>
      montoGarantiaCalc != null &&
      (montoGarantiaCalc! - montoGarantia).abs() >= 0.005;

  GarantiaCbrEntity copyWith({
    BigInt? codGarantia,
    String? codClienteSAP,
    double? montoGarantia,
    double? montoCredito,
    int? tiempoPago,
    DateTime? fechaInicio,
    DateTime? fechaExpiracion,
    double? montoGarantiaCalc,
    String? recFirmas,
    String? nroProtesta,
  }) => GarantiaCbrEntity(
    codGarantia: codGarantia ?? this.codGarantia,
    codClienteSAP: codClienteSAP ?? this.codClienteSAP,
    montoGarantia: montoGarantia ?? this.montoGarantia,
    montoCredito: montoCredito ?? this.montoCredito,
    tiempoPago: tiempoPago ?? this.tiempoPago,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
    montoGarantiaCalc: montoGarantiaCalc ?? this.montoGarantiaCalc,
    recFirmas: recFirmas ?? this.recFirmas,
    nroProtesta: nroProtesta ?? this.nroProtesta,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
