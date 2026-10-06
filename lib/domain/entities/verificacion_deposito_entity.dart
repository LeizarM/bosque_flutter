/// La verificacion del deposito de un cheque (tabla `tch_verificacionDeposito`,
/// pantalla «Verificar Cheques», vista 77).
///
/// Alguien comprueba en el banco que el cheque se deposito y lo deja asentado:
/// en que banco lo vio, que dia y una observacion. Mientras un cheque tiene una
/// verificacion **valida**, el detalle de cheques habilita «Cerrar con
/// verificacion» (rama `K`).
///
/// Anular no borra: la fila pasa a [anulada] y queda en la lista.
class VerificacionDepositoEntity {
  /// `Y`: la verificacion vale.
  static const String valida = 'Y';

  /// `N`: anulada. Sigue en la tabla.
  static const String anulada = 'N';

  /// PK, IDENTITY. 0 en una verificacion que todavia no se guardo.
  final BigInt codvd;

  /// El cheque verificado. No hay FK en la base.
  final BigInt codCheque;

  /// El banco en el que se comprobo el deposito (no tiene por que ser el del
  /// cheque).
  final int? codBanco;

  /// El dia de la verificacion; la base guarda solo la fecha.
  final DateTime? fechaBanco;

  /// Hasta 50 caracteres.
  final String? observacion;

  /// `Y` o `N`.
  final String estado;

  /// Solo lectura: el backend lo toma del token.
  final int? audUsuario;
  final DateTime? audFecha;

  const VerificacionDepositoEntity({
    required this.codvd,
    required this.codCheque,
    required this.codBanco,
    required this.fechaBanco,
    required this.observacion,
    required this.estado,
    required this.audUsuario,
    required this.audFecha,
  });

  bool get esValida => estado.trim() == valida;
  bool get estaAnulada => estado.trim() == anulada;
}
