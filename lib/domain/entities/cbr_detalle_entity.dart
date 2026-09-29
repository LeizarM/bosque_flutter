/// Un documento que respalda una garantia (tabla tcbr_cbrDetalle): un pagare,
/// una letra de cambio, un inmueble, con su monto parcial.
///
/// La suma de los detalles es el `montoGarantiaCalc` de su garantia.
///
/// **Que se puede cambiar despues del alta:** solo [montoGarantiaParc]. El
/// procedimiento ignora el tipo, el texto y la fecha en la edicion, asi que la
/// pantalla no los ofrece editables.
class CbrDetalleEntity {
  /// PK, IDENTITY. Cero en un detalle que todavia no se guardo.
  final BigInt codDetalle;

  final BigInt codGarantia;

  /// La pone el servidor (GETDATE) en el alta.
  final DateTime? fecha;

  /// Codigo del catalogo v_tipos grupo 28 (PAG, LDC, INM, ...).
  final String tipoGarantia;

  final String? detalle;
  final double? montoGarantiaParc;

  /// Solo lectura: el backend lo toma del token.
  final int audUsuario;
  final DateTime? audFecha;

  const CbrDetalleEntity({
    required this.codDetalle,
    required this.codGarantia,
    required this.fecha,
    required this.tipoGarantia,
    required this.detalle,
    required this.montoGarantiaParc,
    required this.audUsuario,
    required this.audFecha,
  });

  /// Un detalle para agregar: sin id, sin fecha, sin auditoria.
  factory CbrDetalleEntity.nuevo({
    required BigInt codGarantia,
    required String tipoGarantia,
    required String? detalle,
    required double? montoGarantiaParc,
  }) => CbrDetalleEntity(
    codDetalle: BigInt.zero,
    codGarantia: codGarantia,
    fecha: null,
    tipoGarantia: tipoGarantia,
    detalle: detalle,
    montoGarantiaParc: montoGarantiaParc,
    audUsuario: 0,
    audFecha: null,
  );

  bool get esNuevo => codDetalle == BigInt.zero;

  double get monto => montoGarantiaParc ?? 0;

  CbrDetalleEntity copyWith({double? montoGarantiaParc}) => CbrDetalleEntity(
    codDetalle: codDetalle,
    codGarantia: codGarantia,
    fecha: fecha,
    tipoGarantia: tipoGarantia,
    detalle: detalle,
    montoGarantiaParc: montoGarantiaParc ?? this.montoGarantiaParc,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );
}
