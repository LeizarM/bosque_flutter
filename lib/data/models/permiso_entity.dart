class PermisoEntity {
  final int codPermiso;
  final int codEmpleado;
  final String tipoPermiso;
  final DateTime? desde;
  final DateTime? hasta;
  final String motivo;
  final double cantidadDias;
  final double cantidadDiasTotal;
  final int codRelEmplEmpr;
  final int audUsuarioI;
  final DateTime? audFechaI;
  final double cantidadDiasAsig;
  final double cantidadDiasAbon;
  final DateTime? fecRango;

  PermisoEntity({
    required this.codPermiso,
    required this.codEmpleado,
    required this.tipoPermiso,
    this.desde,
    this.hasta,
    required this.motivo,
    required this.cantidadDias,
    required this.cantidadDiasTotal,
    required this.codRelEmplEmpr,
    required this.audUsuarioI,
    this.audFechaI,
    required this.cantidadDiasAsig,
    required this.cantidadDiasAbon,
    this.fecRango,
  });

  PermisoEntity copyWith({
    int? codPermiso,
    int? codEmpleado,
    String? tipoPermiso,
    DateTime? desde,
    DateTime? hasta,
    String? motivo,
    double? cantidadDias,
    double? cantidadDiasTotal,
    int? codRelEmplEmpr,
    int? audUsuarioI,
    DateTime? audFechaI,
    double? cantidadDiasAsig,
    double? cantidadDiasAbon,
    DateTime? fecRango,
  }) {
    return PermisoEntity(
      codPermiso: codPermiso ?? this.codPermiso,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      tipoPermiso: tipoPermiso ?? this.tipoPermiso,
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
      motivo: motivo ?? this.motivo,
      cantidadDias: cantidadDias ?? this.cantidadDias,
      cantidadDiasTotal: cantidadDiasTotal ?? this.cantidadDiasTotal,
      codRelEmplEmpr: codRelEmplEmpr ?? this.codRelEmplEmpr,
      audUsuarioI: audUsuarioI ?? this.audUsuarioI,
      audFechaI: audFechaI ?? this.audFechaI,
      cantidadDiasAsig: cantidadDiasAsig ?? this.cantidadDiasAsig,
      cantidadDiasAbon: cantidadDiasAbon ?? this.cantidadDiasAbon,
      fecRango: fecRango ?? this.fecRango,
    );
  }
}
