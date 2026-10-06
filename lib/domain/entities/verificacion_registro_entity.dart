/// Lo que se manda a `/cheque/verificacion/registrar`: el alta de una
/// verificacion o la edicion de una existente.
///
/// **No lleva estado**: el servidor lo fija (`Y` en el alta) o lo conserva (en la
/// edicion). Tampoco lleva usuario: sale del token. En la edicion el cheque
/// tampoco cambia: el servidor usa el de la verificacion guardada.
class VerificacionRegistroEntity {
  /// 0 = alta.
  final BigInt codvd;

  final BigInt codCheque;
  final int codBanco;

  /// Obligatoria.
  final DateTime fechaBanco;

  /// Hasta 50 caracteres: letras sin tilde ni ñ, digitos, espacio, apostrofe,
  /// coma y punto. Vacia = sin observacion.
  final String observacion;

  const VerificacionRegistroEntity({
    required this.codvd,
    required this.codCheque,
    required this.codBanco,
    required this.fechaBanco,
    required this.observacion,
  });

  bool get esAlta => codvd == BigInt.zero;
}
