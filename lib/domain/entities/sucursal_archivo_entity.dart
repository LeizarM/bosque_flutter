/// Una sucursal para el combo del archivo físico. `tb_sucursal` se repite por
/// empresa (hay tres «Achocalla»), así que el rótulo lleva la empresa.
class SucursalArchivoEntity {
  final int codSucursal;
  final String nombre;
  final int codEmpresa;
  final String? nombreEmpresa;
  final String? ciudad;

  const SucursalArchivoEntity({
    required this.codSucursal,
    required this.nombre,
    this.codEmpresa = 0,
    this.nombreEmpresa,
    this.ciudad,
  });

  /// «Sucursal 15 Achocalla · IMPEXPAP · LA PAZ».
  String get rotulo => [
    nombre.trim(),
    if ((nombreEmpresa ?? '').trim().isNotEmpty) nombreEmpresa!.trim(),
    if ((ciudad ?? '').trim().isNotEmpty) ciudad!.trim(),
  ].join(' · ');
}
