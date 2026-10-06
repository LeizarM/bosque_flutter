import 'package:bosque_flutter/domain/entities/datos_cheque_verificacion_entity.dart';
import 'package:bosque_flutter/domain/entities/verificacion_deposito_entity.dart';

/// Una fila de la lista principal: la verificacion y, por JOIN, el cheque
/// verificado (`VerificacionFila` del contrato).
///
/// Envuelve a [VerificacionDepositoEntity] en vez de repetir sus columnas: lo que
/// se edita y se manda de vuelta es [verificacion].
class VerificacionFilaEntity {
  final VerificacionDepositoEntity verificacion;

  /// El cheque verificado: numero, monto, banco, fecha de cobranza y estado.
  final DatosChequeVerificacionEntity cheque;

  /// Nombre del banco en el que se comprobo el deposito.
  final String datoBanco;

  /// «Valido» o «Anulado».
  final String datoEstado;

  /// Numero de fila, 1..total, segun el orden del servidor.
  final int fila;

  const VerificacionFilaEntity({
    required this.verificacion,
    required this.cheque,
    required this.datoBanco,
    required this.datoEstado,
    required this.fila,
  });

  BigInt get codvd => verificacion.codvd;
  BigInt get codCheque => verificacion.codCheque;
  bool get esValida => verificacion.esValida;
  bool get estaAnulada => verificacion.estaAnulada;
}
