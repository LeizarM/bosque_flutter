/// Un empleado (`tb_empleado`) para elegir al responsable de un archivo o a
/// quién se le presta. Los inactivos solo llegan si ya son responsables.
class EmpleadoArchivoEntity {
  final int codEmpleado;
  final String nombreCompleto;
  final String? cargo;
  final bool activo;

  const EmpleadoArchivoEntity({
    required this.codEmpleado,
    required this.nombreCompleto,
    this.cargo,
    this.activo = true,
  });

  /// «CÁRDENAS RIVEROS VICTOR HUMBERTO · AUXILIAR CONTABLE»: el cargo separa homónimos.
  String get rotulo => [
    nombreCompleto.trim(),
    if ((cargo ?? '').trim().isNotEmpty) cargo!.trim(),
    if (!activo) 'ya no está activo',
  ].join(' · ');
}
