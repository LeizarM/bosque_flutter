/// Una postergacion de un cheque (tabla `tch_chPostergacion`): la constancia de
/// que el cobro se movio, con su fecha, el motivo y, aparte, un PDF opcional
/// (la carta del cliente, por ejemplo).
///
/// El PDF **no esta en la base**: es un archivo `<codPostergacion>.pdf` en una
/// carpeta del servidor. `nombreArchivo` queda siempre vacio (ni el legacy lo
/// escribe) y lo que dice si hay PDF es [tienePdf].
class PostergacionEntity {
  /// PK, IDENTITY.
  final BigInt codPostergacion;

  /// Cheque al que pertenece. No hay FK en la base.
  final BigInt codCheque;

  /// Fecha de la postergacion (solo dia).
  final DateTime? fecha;

  /// El motivo: mas de 2 y hasta 200 caracteres, texto libre (puede traer
  /// saltos de linea).
  final String observacion;

  /// Columna de la tabla: siempre vacia (ver arriba).
  final String nombreArchivo;

  final int? audUsuario;

  /// Cuando se registro (no es [fecha]).
  final DateTime? audFecha;

  /// Si el servidor encontro el PDF de esta postergacion. **Null = no se pudo
  /// saber** (la carpeta de PDF del servidor no esta configurada o no esta
  /// disponible): el listado no falla por eso.
  final bool? tienePdf;

  /// Numero de fila, 1..n, dentro del cheque. Lo pone el servidor.
  final int fila;

  const PostergacionEntity({
    required this.codPostergacion,
    required this.codCheque,
    required this.fecha,
    required this.observacion,
    this.nombreArchivo = '',
    this.audUsuario,
    this.audFecha,
    this.tienePdf,
    this.fila = 0,
  });
}
