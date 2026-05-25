class AnticipoDetalleEntity {
  final int codAntDetalle;
  final int codAnticipo;
  final int codEmpleado;
  final String nombreCompleto;
  final double monto;
  final int codAutorizacion;
  final String estadoAnticipo;
  final DateTime fechaAnticipo;
  final String descripcion;
  final int audUsuarioI;
  final int? fila;
  final int? pagina;
  final int? tamanoPagina;
  final int? totalPaginas;
  final String? search;
  final int? totalRegistros;
  final int? codEmpresa;

  AnticipoDetalleEntity({
    required this.codAntDetalle,
    required this.codAnticipo,
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.monto,
    required this.codAutorizacion,
    required this.estadoAnticipo,
    required this.fechaAnticipo,
    required this.descripcion,
    required this.audUsuarioI,
    this.fila,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.search,
    this.totalRegistros,
    this.codEmpresa,
  });
  AnticipoDetalleEntity copyWith({
    int? codAntDetalle,
    int? codAnticipo,
    int? codEmpleado,
    String? nombreCompleto,
    double? monto,
    int? codAutorizacion,
    String? estadoAnticipo,
    DateTime? fechaAnticipo,
    String? descripcion,
    int? audUsuarioI,
    int? fila,
    int? pagina,
    int? tamanoPagina,
    int? totalPaginas,
    String? search,
    int? totalRegistros,
    int? codEmpresa,
  }) {
    return AnticipoDetalleEntity(
      codAntDetalle: codAntDetalle ?? this.codAntDetalle,
      codAnticipo: codAnticipo ?? this.codAnticipo,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      monto: monto ?? this.monto,
      codAutorizacion: codAutorizacion ?? this.codAutorizacion,
      estadoAnticipo: estadoAnticipo ?? this.estadoAnticipo,
      fechaAnticipo: fechaAnticipo ?? this.fechaAnticipo,
      descripcion: descripcion ?? this.descripcion,
      audUsuarioI: audUsuarioI ?? this.audUsuarioI,
      fila: fila ?? this.fila,
      pagina: pagina ?? this.pagina,
      tamanoPagina: tamanoPagina ?? this.tamanoPagina,
      totalPaginas: totalPaginas ?? this.totalPaginas,
      search: search ?? this.search,
      totalRegistros: totalRegistros ?? this.totalRegistros,
      codEmpresa: codEmpresa ?? this.codEmpresa,
    );
  }
}
