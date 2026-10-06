/// «A Custodio» (`/cheque/custodia`, `CustodiaChequeRequest` del contrato):
/// entrega varios cheques al responsable elegido. Cada uno recibe una accion
/// CUS. Es todo o nada.
class CustodiaChequeRequestEntity {
  final int codSucursal;

  /// Jefe de cobranzas o cobrador que se lleva los cheques.
  final int codEmpleado;

  final List<BigInt> codCheques;

  const CustodiaChequeRequestEntity({
    required this.codSucursal,
    required this.codEmpleado,
    required this.codCheques,
  });
}
