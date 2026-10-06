/// Una sucursal de una empresa, para el combo de la pantalla de cheques
/// (`/cheque/sucursales`).
class SucursalChequeEntity {
  /// `bigint` en la base; en Dart cabe de sobra en un `int`.
  final int codSucursal;
  final String nombre;

  const SucursalChequeEntity({required this.codSucursal, required this.nombre});
}
