class AnticipoEntity {
  final int codAnticipo;
  final int codEmpresa;
  final String db;
  final String codigoCuenta;
  final String nombreCuenta;
  final DateTime fechaAsiento;
  final String numAsiento;
  final String concepto;
  final String referencia;
  final double debe;
  final double haber;
  final String estado;
  final int audUsuario;
  final int? fila;
  final int? pagina;
  final int? tamanoPagina;
  final int? totalPaginas;
  final String? search;
  final int? totalRegistros;
  final String? moduloOrigen;
  final String? mes;
  final String? anio;

  AnticipoEntity({
    required this.codAnticipo,
    required this.codEmpresa,
    required this.db,
    required this.codigoCuenta,
    required this.nombreCuenta,
    required this.fechaAsiento,
    required this.numAsiento,
    required this.concepto,
    required this.referencia,
    required this.debe,
    required this.haber,
    required this.estado,
    required this.audUsuario,
    this.fila,
    this.pagina,
    this.tamanoPagina,
    this.totalPaginas,
    this.search,
    this.totalRegistros,
    this.moduloOrigen,
    this.mes,
    this.anio,
  });
  AnticipoEntity copyWith({
    int? codAnticipo,
    int? codEmpresa,
    String? db,
    String? codigoCuenta,
    String? nombreCuenta,
    DateTime? fechaAsiento,
    String? numAsiento,
    String? concepto,
    String? referencia,
    double? debe,
    double? haber,
    String? estado,
    int? audUsuario,
    int? fila,
    int? pagina,
    int? tamanoPagina,
    int? totalPaginas,
    String? search,
    int? totalRegistros,
    String? moduloOrigen,
    String? mes,
    String? anio,
  }) => AnticipoEntity(
    codAnticipo: codAnticipo ?? this.codAnticipo,
    codEmpresa: codEmpresa ?? this.codEmpresa,
    db: db ?? this.db,
    codigoCuenta: codigoCuenta ?? this.codigoCuenta,
    nombreCuenta: nombreCuenta ?? this.nombreCuenta,
    fechaAsiento: fechaAsiento ?? this.fechaAsiento,
    numAsiento: numAsiento ?? this.numAsiento,
    concepto: concepto ?? this.concepto,
    referencia: referencia ?? this.referencia,
    debe: debe ?? this.debe,
    haber: haber ?? this.haber,
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
    fila: fila ?? this.fila,
    pagina: pagina ?? this.pagina,
    tamanoPagina: tamanoPagina ?? this.tamanoPagina,
    totalPaginas: totalPaginas ?? this.totalPaginas,
    search: search ?? this.search,
    totalRegistros: totalRegistros ?? this.totalRegistros,
    moduloOrigen: moduloOrigen ?? this.moduloOrigen,
    mes: mes ?? this.mes,
    anio: anio ?? this.anio,
  );
}
