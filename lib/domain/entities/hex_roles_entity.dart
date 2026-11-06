/// Roles de aprobación del usuario: encargado (nivel 1), jefe de área (nivel
/// 2) y/o observador (nivel 3, solo lectura) de su rama (D34, D45). Lo calcula
/// el SP; la app solo lo muestra.
class HexRolesEntity {
  final bool esEncargado;
  final bool esJefe;

  /// D45: ve los reportes y su historial de los encargados que se le asignan;
  /// no firma ni aprueba.
  final bool esObservador;

  /// Sucursales donde trabajan los empleados de su rama, por ejemplo `1,4`.
  final String? sucursales;

  const HexRolesEntity({
    this.esEncargado = false,
    this.esJefe = false,
    this.esObservador = false,
    this.sucursales,
  });
}
