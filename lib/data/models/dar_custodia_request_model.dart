import 'package:bosque_flutter/domain/entities/dar_custodia_request_entity.dart';

/// Cuerpo de `/cheque/dar-custodia`. Solo de ida: el backend responde el
/// `codAccion` nuevo.
class DarCustodiaRequestModel {
  final DarCustodiaRequestEntity pedido;

  const DarCustodiaRequestModel._(this.pedido);

  factory DarCustodiaRequestModel.fromEntity(DarCustodiaRequestEntity e) =>
      DarCustodiaRequestModel._(e);

  Map<String, dynamic> toJson() => {
    'codSucursal': pedido.codSucursal,
    'codAccionOrigen': pedido.codAccionOrigen.toInt(),
    'codCheque': pedido.codCheque.toInt(),
  };
}
