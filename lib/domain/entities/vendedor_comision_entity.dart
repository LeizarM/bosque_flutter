/// Vendedor del modulo de comisiones (tabla tcom_Vendedor).
///
/// Los codigos por empresa SAP llegan planos desde la vista v_tcom_VendedorSap.
/// En el alta se envian como XML, porque SQL Server 2008 no soporta JSON.
class VendedorComisionEntity {
  final BigInt idVendedor;
  final String nomVenSap;
  final double comision;
  final int esInterno;
  final int activo;
  final BigInt audUsuario;

  final int? codVenPapirus;
  final int? codVenImpexpap;
  final int? codVenPapelbol;
  final int? codVenEsppapel;
  final int? codVenProdpap;

  const VendedorComisionEntity({
    required this.idVendedor,
    required this.nomVenSap,
    required this.comision,
    required this.esInterno,
    required this.activo,
    required this.audUsuario,
    this.codVenPapirus,
    this.codVenImpexpap,
    this.codVenPapelbol,
    this.codVenEsppapel,
    this.codVenProdpap,
  });

  double get comisionVisual => comision;

  bool get estaActivo => activo == 1;

  /// Codigos cargados, listos para mostrar como chips en la ficha.
  Map<String, int> get codigosPorEmpresa {
    final mapa = <String, int>{};
    if (codVenPapirus != null) mapa['PAPIRUS'] = codVenPapirus!;
    if (codVenImpexpap != null) mapa['IMPEXPAP'] = codVenImpexpap!;
    if (codVenPapelbol != null) mapa['PAPELBOL'] = codVenPapelbol!;
    if (codVenEsppapel != null) mapa['ESPPAPEL'] = codVenEsppapel!;
    if (codVenProdpap != null) mapa['PRODPAP'] = codVenProdpap!;
    return mapa;
  }

  VendedorComisionEntity copyWith({
    BigInt? idVendedor,
    String? nomVenSap,
    double? comision,
    int? esInterno,
    int? activo,
    BigInt? audUsuario,
    int? codVenPapirus,
    int? codVenImpexpap,
    int? codVenPapelbol,
    int? codVenEsppapel,
    int? codVenProdpap,
  }) => VendedorComisionEntity(
    idVendedor: idVendedor ?? this.idVendedor,
    nomVenSap: nomVenSap ?? this.nomVenSap,
    comision: comision ?? this.comision,
    esInterno: esInterno ?? this.esInterno,
    activo: activo ?? this.activo,
    audUsuario: audUsuario ?? this.audUsuario,
    codVenPapirus: codVenPapirus ?? this.codVenPapirus,
    codVenImpexpap: codVenImpexpap ?? this.codVenImpexpap,
    codVenPapelbol: codVenPapelbol ?? this.codVenPapelbol,
    codVenEsppapel: codVenEsppapel ?? this.codVenEsppapel,
    codVenProdpap: codVenProdpap ?? this.codVenProdpap,
  );
}
