class PrestamoDetalleEntity {
  final int codPrestDetalle;
  final int codPrestamo;
  final String? tipoPago;
  final String? datoPago;
  final String? detalle;
  final String? observacion;
  final String? postergado;
  final String? estadoCuota;
  final int? numeroCuota;
  final double montoPago;
  final double debe;
  final double haber;
  final double saldo;
  final DateTime? fechaPago;
  final int? audUsuario;
  final DateTime? audFecha;

  PrestamoDetalleEntity({
    required this.codPrestDetalle,
    required this.codPrestamo,
    this.tipoPago,
    this.datoPago,
    this.detalle,
    this.observacion,
    this.postergado,
    this.estadoCuota,
    this.numeroCuota,
    required this.montoPago,
    required this.debe,
    required this.haber,
    required this.saldo,
    this.fechaPago,
    this.audUsuario,
    this.audFecha,
  });

  PrestamoDetalleEntity copyWith({
    int? codPrestDetalle,
    int? codPrestamo,
    String? tipoPago,
    String? datoPago,
    String? detalle,
    String? observacion,
    String? postergado,
    String? estadoCuota,
    int? numeroCuota,
    double? montoPago,
    double? debe,
    double? haber,
    double? saldo,
    DateTime? fechaPago,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return PrestamoDetalleEntity(
      codPrestDetalle: codPrestDetalle ?? this.codPrestDetalle,
      codPrestamo: codPrestamo ?? this.codPrestamo,
      tipoPago: tipoPago ?? this.tipoPago,
      datoPago: datoPago ?? this.datoPago,
      detalle: detalle ?? this.detalle,
      observacion: observacion ?? this.observacion,
      postergado: postergado ?? this.postergado,
      estadoCuota: estadoCuota ?? this.estadoCuota,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      montoPago: montoPago ?? this.montoPago,
      debe: debe ?? this.debe,
      haber: haber ?? this.haber,
      saldo: saldo ?? this.saldo,
      fechaPago: fechaPago ?? this.fechaPago,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
