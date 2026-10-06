/// «Dar Custodia», solo administrador (`/cheque/dar-custodia`,
/// `DarCustodiaRequest` del contrato): copia una accion CUS ya hecha a otro
/// cheque, con la misma fecha, responsable y observacion.
class DarCustodiaRequestEntity {
  final int codSucursal;

  /// La accion CUS que se copia, de la lista de entregas del dia. Debe ser CUS.
  final BigInt codAccionOrigen;

  /// El cheque que la recibe.
  final BigInt codCheque;

  const DarCustodiaRequestEntity({
    required this.codSucursal,
    required this.codAccionOrigen,
    required this.codCheque,
  });
}
