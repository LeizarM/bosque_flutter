class MultaEntity {
  final int codMulta;
  final int codEmpleado;
  final int? anio;
  final int? mes;
  final double? diasTrabajados;
  final double? diasMulta;
  final double monto;
  // final String estado;
  final int audUsuarioI;
  final int? fila;
  final int? pagina;
  final int? tamanoPagina;
  final int? totalPaginas;
  final String? search;
  final int? totalRegistros;
  final String nombreCompleto;
  final String seguroNombre;
  final double haberBasico;
  final int? codEmpresa;

  MultaEntity({
    required this.codMulta,
    required this.codEmpleado,
    required this.anio,
    required this.mes,
    required this.diasTrabajados,
    required this.diasMulta,
    required this.monto,
    // required this.estado,
    required this.audUsuarioI,
    required this.fila,
    required this.pagina,
    required this.tamanoPagina,
    required this.totalPaginas,
    required this.search,
    required this.totalRegistros,
    required this.nombreCompleto,
    required this.seguroNombre,
    required this.haberBasico,
    this.codEmpresa,
  });

  MultaEntity copyWith({
    int? codMulta,
    int? codEmpleado,
    int? anio,
    int? mes,
    double? diasTrabajados,
    double? diasMulta,
    double? monto,
    //String? estado,
    int? audUsuarioI,
    int? fila,
    int? pagina,
    int? tamanoPagina,
    int? totalPaginas,
    String? search,
    int? totalRegistros,
    String? nombreCompleto,
    String? seguroNombre,
    double? haberBasico,
    int? codEmpresa,
  }) {
    return MultaEntity(
      codMulta: codMulta ?? this.codMulta,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      anio: anio ?? this.anio,
      mes: mes ?? this.mes,
      diasTrabajados: diasTrabajados ?? this.diasTrabajados,
      diasMulta: diasMulta ?? this.diasMulta,
      monto: monto ?? this.monto,
      // estado: estado ?? this.estado,
      audUsuarioI: audUsuarioI ?? this.audUsuarioI,
      fila: fila ?? this.fila,
      pagina: pagina ?? this.pagina,
      tamanoPagina: tamanoPagina ?? this.tamanoPagina,
      totalPaginas: totalPaginas ?? this.totalPaginas,
      search: search ?? this.search,
      totalRegistros: totalRegistros ?? this.totalRegistros,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      seguroNombre: seguroNombre ?? this.seguroNombre,
      haberBasico: haberBasico ?? this.haberBasico,
      codEmpresa: codEmpresa ?? this.codEmpresa,
    );
  }
}
