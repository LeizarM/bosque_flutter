/// Un numero de transaccion bancaria de un cheque (tabla
/// `tch_chTransaccionBancaria`): la referencia del deposito o la transferencia
/// con la que se cobro.
///
/// La tabla **no tiene clave primaria**: una transaccion se identifica por
/// `codCheque` + `nroTransaccion`. Eliminar una elimina todas las que
/// coincidan.
class TransaccionBancariaEntity {
  /// Cheque al que pertenece. No hay FK en la base.
  final BigInt codCheque;

  /// El numero que da el banco: mas de 4 y hasta 30 caracteres.
  final String nroTransaccion;

  /// Banco de la transaccion (`tch_banco`).
  final int codBanco;

  /// Fecha de la transaccion (solo dia).
  final DateTime? fechaTransaccion;

  /// Nombre del banco. Lo trae el listado (JOIN con `tch_banco`); vacio en una
  /// transaccion que todavia no se guardo.
  final String datoBanco;

  /// El listado del servidor no los devuelve: quedan en null.
  final int? audUsuario;
  final DateTime? audFecha;

  /// Numero de fila, 1..n, dentro del cheque. Lo pone el servidor.
  final int fila;

  const TransaccionBancariaEntity({
    required this.codCheque,
    required this.nroTransaccion,
    required this.codBanco,
    required this.fechaTransaccion,
    this.datoBanco = '',
    this.audUsuario,
    this.audFecha,
    this.fila = 0,
  });
}
