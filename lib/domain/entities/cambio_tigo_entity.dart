class CambiosTigoEntity {
  final int codCambio;
  final int codEmpleado;
  final int codTelefono;
  final int codCuenta;
  final String nombreOrigen;
  final String nombreCompleto;
  final String telefono;
  final String tipoSocio;
  final String descripcion;
  final String estado;
  final String periodoCobrado;
  final int audUsuario;
  // Campos de filtro (solo se envian, no se reciben)
  final String? search;
  final int fila;
  final int pagina;
  final int tamanoPagina;
  final int totalPaginas;

  CambiosTigoEntity({
    this.codCambio = 0,
    this.codEmpleado = 0,
    this.codTelefono = 0,
    this.codCuenta = 0,
    this.nombreOrigen = '',
    this.nombreCompleto = '',
    this.telefono = '',
    this.tipoSocio = '',
    this.descripcion = '',
    this.estado = '',
    this.periodoCobrado = '',
    this.audUsuario = 0,
    this.search,
    this.fila = 0,
    this.pagina = 1,
    this.tamanoPagina = 15,
    this.totalPaginas = 1,
  });

  CambiosTigoEntity copyWith({
    int? codCambio,
    int? codEmpleado,
    int? codTelefono,
    int? codCuenta,
    String? nombreOrigen,
    String? nombreCompleto,
    String? telefono,
    String? tipoSocio,
    String? descripcion,
    String? estado,
    String? periodoCobrado,
    int? audUsuario,
    String? search,
    int? totalPaginas,
  }) {
    return CambiosTigoEntity(
      codCambio: codCambio ?? this.codCambio,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      codTelefono: codTelefono ?? this.codTelefono,
      codCuenta: codCuenta ?? this.codCuenta,
      nombreOrigen: nombreOrigen ?? this.nombreOrigen,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      telefono: telefono ?? this.telefono,
      tipoSocio: tipoSocio ?? this.tipoSocio,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      periodoCobrado: periodoCobrado ?? this.periodoCobrado,
      audUsuario: audUsuario ?? this.audUsuario,
      search: search ?? this.search,
      totalPaginas: totalPaginas ?? this.totalPaginas,
    );
  }
}
