import 'package:bosque_flutter/domain/entities/datos_cheque_verificacion_entity.dart';

/// Un cheque que todavia no tiene una verificacion valida: una fila del modal
/// «Cheques pendientes sin regularizar» (`ChequePendienteFila` del contrato).
///
/// No es una tabla: lo arma el procedimiento con el cheque y su banco. Un cheque
/// [DatosChequeVerificacionEntity.chequeCerrado] se lista pero no se puede
/// seleccionar.
class ChequePendienteVerificacionEntity {
  final DatosChequeVerificacionEntity cheque;

  /// El banco **del cheque**: es el que se propone como banco de verificacion.
  final int? codBancoCheque;

  /// Numero de fila, 1..total, segun el orden del servidor.
  final int fila;

  const ChequePendienteVerificacionEntity({
    required this.cheque,
    required this.codBancoCheque,
    required this.fila,
  });

  BigInt get codCheque => cheque.codCheque;

  /// Se puede elegir para verificar: el legacy no ofrecia «Seleccionar» en un
  /// cheque cerrado y el servidor tampoco lo acepta.
  bool get seleccionable => !cheque.chequeCerrado;
}
