import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';

/// Lo que devuelve `/cheque/verificacion/preparar` al elegir un cheque del modal
/// «Cheques pendientes sin regularizar»: el cheque como esta **ahora** en el
/// servidor y la fecha de verificacion que se propone (hoy).
///
/// Si el cheque ya no se puede verificar (alguien lo verifico mientras tanto, o
/// se cerro), el servidor responde 400 con el motivo y no hay [VerificacionPreparadaEntity].
class VerificacionPreparadaEntity {
  final ChequePendienteVerificacionEntity cheque;

  /// El dia propuesto para la verificacion: hoy, segun el reloj del servidor.
  final DateTime fechaBanco;

  const VerificacionPreparadaEntity({
    required this.cheque,
    required this.fechaBanco,
  });
}
