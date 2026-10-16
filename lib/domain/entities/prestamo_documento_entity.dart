/// Un renglón de una entrega (`tarc_prestamo`): una línea de la caja o la caja
/// completa ([codContenido] null). Sigue afuera mientras no tiene
/// [fechaDevolucion]; las fechas las pone el servidor y llegan como texto.
class PrestamoDocumentoEntity {
  final int codPrestamo;
  final int codEntrega;
  final int codCaja;
  final int? codContenido;
  final String? fechaDevolucion;

  /// La nota que se dejó al volver.
  final String? observacionDevolucion;
  final int audUsuario;
  final DateTime? audFecha;

  /// Solo lectura: la caja, el documento y los nombres que trae el listado.
  final int numeroCaja;
  final int codArchivo;
  final String? nombreArchivo;
  final String? nombreTipoDocumento;
  final String? detalle;
  final String? gestion;

  /// De la cabecera de la entrega: a quién, cuándo y para qué.
  final int codEmpleado;
  final String? nombreEmpleado;
  final String? fechaEntrega;
  final String? observacionEntrega;

  /// Quién hizo el último registro (la entrega o la devolución).
  final String? nombreUsuario;

  const PrestamoDocumentoEntity({
    required this.codPrestamo,
    required this.codEntrega,
    required this.codCaja,
    this.codContenido,
    this.fechaDevolucion,
    this.observacionDevolucion,
    this.audUsuario = 0,
    this.audFecha,
    this.numeroCaja = 0,
    this.codArchivo = 0,
    this.nombreArchivo,
    this.nombreTipoDocumento,
    this.detalle,
    this.gestion,
    this.codEmpleado = 0,
    this.nombreEmpleado,
    this.fechaEntrega,
    this.observacionEntrega,
    this.nombreUsuario,
  });

  bool get abierto => (fechaDevolucion ?? '').isEmpty;
  bool get cajaCompleta => codContenido == null;
}
