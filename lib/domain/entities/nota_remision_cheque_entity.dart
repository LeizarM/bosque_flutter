/// Una nota de remision de un cheque (tabla `tch_notaRemision`): el documento
/// que acompana a la factura que el cheque paga. **No es la nota de remision de
/// Depositos** (`NotaRemisionEntity`, tabla `tdep_NotaRemision`).
///
/// La tabla **no tiene clave primaria**: de hecho una nota se identifica por
/// `codCheque` + `notaRemision`, y nada impide que el mismo par figure dos
/// veces (en la base de prueba hay 41 pares repetidos). Eliminar una nota
/// elimina **todas** las que tengan ese par.
class NotaRemisionChequeEntity {
  /// Cheque al que pertenece (FK a `tch_cheque`).
  final BigInt codCheque;

  /// Numero de la nota: 5 a 10 digitos (con espacios, como el legacy).
  final String notaRemision;

  /// Numero de la factura, de 1 a 999999.
  final int nroFactura;

  /// Fecha de la factura (solo dia).
  final DateTime? fechaFactura;

  /// Solo lectura: el backend lo toma del token.
  final int? audUsuario;
  final DateTime? audFecha;

  /// Numero de fila, 1..n, dentro del cheque. Lo pone el servidor.
  final int fila;

  const NotaRemisionChequeEntity({
    required this.codCheque,
    required this.notaRemision,
    required this.nroFactura,
    required this.fechaFactura,
    this.audUsuario,
    this.audFecha,
    this.fila = 0,
  });
}
