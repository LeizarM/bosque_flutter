class ChipTigoEntity {
  final int codLinea;
  final int codEmpleado;
  final DateTime fechaSolicitud;
  final String telefono;
  final String nombreCompleto;
  final String descripcion;
  final int audUsuarioI;
  final DateTime audFechaI;
  final String? search;
  final int? fila;
  final int? pagina;
  final int? tamanoPagina;
  final String? periodo;
  final String? codigo;
  ChipTigoEntity({
    required this.codLinea,
    required this.codEmpleado,
    required this.fechaSolicitud,
    required this.telefono,
    required this.nombreCompleto,
    required this.descripcion,
    required this.audUsuarioI,
    required this.audFechaI,
    this.search,
    this.fila,
    this.pagina,
    this.tamanoPagina,
    this.periodo,
    this.codigo,
  });
  //metodo copyWith
  ChipTigoEntity copyWith({
    int? codLinea,
    int? codEmpleado,
    DateTime? fechaSolicitud,
    String? telefono,
    String? nombreCompleto,
    String? descripcion,
    int? audUsuarioI,
    DateTime? audFechaI,
    String? search,
    int? fila,
    int? pagina,
    int? tamanoPagina,
    String? periodo,
    String? codigo,
  }) {
    return ChipTigoEntity(
      codLinea: codLinea ?? this.codLinea,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
      telefono: telefono ?? this.telefono,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      descripcion: descripcion ?? this.descripcion,
      audUsuarioI: audUsuarioI ?? this.audUsuarioI,
      audFechaI: audFechaI ?? this.audFechaI,
      search: search ?? this.search,
      fila: fila ?? this.fila,
      pagina: pagina ?? this.pagina,
      tamanoPagina: tamanoPagina ?? this.tamanoPagina,
      periodo: periodo ?? this.periodo,
      codigo: codigo ?? this.codigo,
    );
  }

}