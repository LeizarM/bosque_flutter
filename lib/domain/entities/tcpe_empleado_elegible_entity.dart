/// Un empleado vigente para elegir en un lote (`p_list_tcpe_Lote` E): su CI, su
/// cargo actual y, si no se le puede asignar un examen, el motivo que da el SQL.
class TcpeEmpleadoElegibleEntity {
  final BigInt codEmpleado;
  final String? nombreCompleto;
  final String? ci;
  final String? cargo;
  final bool puedeRendir;
  final String? motivo;

  const TcpeEmpleadoElegibleEntity({
    required this.codEmpleado,
    this.nombreCompleto,
    this.ci,
    this.cargo,
    this.puedeRendir = true,
    this.motivo,
  });

  TcpeEmpleadoElegibleEntity copyWith({
    BigInt? codEmpleado,
    String? nombreCompleto,
    String? ci,
    String? cargo,
    bool? puedeRendir,
    String? motivo,
  }) => TcpeEmpleadoElegibleEntity(
    codEmpleado: codEmpleado ?? this.codEmpleado,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    ci: ci ?? this.ci,
    cargo: cargo ?? this.cargo,
    puedeRendir: puedeRendir ?? this.puedeRendir,
    motivo: motivo ?? this.motivo,
  );
}
