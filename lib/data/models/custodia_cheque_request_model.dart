import 'package:bosque_flutter/domain/entities/custodia_cheque_request_entity.dart';

/// Cuerpo de `/cheque/custodia`. Solo de ida: el backend responde cuantos.
class CustodiaChequeRequestModel {
  final CustodiaChequeRequestEntity pedido;

  const CustodiaChequeRequestModel._(this.pedido);

  factory CustodiaChequeRequestModel.fromEntity(
    CustodiaChequeRequestEntity e,
  ) => CustodiaChequeRequestModel._(e);

  Map<String, dynamic> toJson() => {
    'codSucursal': pedido.codSucursal,
    'codEmpleado': pedido.codEmpleado,
    'codCheques': [for (final c in pedido.codCheques) c.toInt()],
  };
}
