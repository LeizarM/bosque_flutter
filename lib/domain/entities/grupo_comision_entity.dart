/// Grupo de comision (tabla tcom_grupo).
///
/// El porcentaje se guarda en PUNTOS PORCENTUALES: 0.7 significa 0,7%.
/// La division entre 100 la hace el SP de calculo, no la aplicacion.
class GrupoComisionEntity {
  final BigInt idGrupo;
  final String grupo;
  final double porcentaje;
  final int esParaVenta;
  final int esInterno;
  final int? bd;
  final String siglaEmpresa;
  final int activo;
  final BigInt audUsuario;

  const GrupoComisionEntity({
    required this.idGrupo,
    required this.grupo,
    required this.porcentaje,
    required this.esParaVenta,
    required this.esInterno,
    this.bd,
    required this.siglaEmpresa,
    required this.activo,
    required this.audUsuario,
  });

  /// Valor listo para mostrar. Coincide con el almacenado: ya son puntos.
  double get porcentajeVisual => porcentaje;

  bool get estaActivo => activo == 1;

  GrupoComisionEntity copyWith({
    BigInt? idGrupo,
    String? grupo,
    double? porcentaje,
    int? esParaVenta,
    int? esInterno,
    int? bd,
    String? siglaEmpresa,
    int? activo,
    BigInt? audUsuario,
  }) => GrupoComisionEntity(
    idGrupo: idGrupo ?? this.idGrupo,
    grupo: grupo ?? this.grupo,
    porcentaje: porcentaje ?? this.porcentaje,
    esParaVenta: esParaVenta ?? this.esParaVenta,
    esInterno: esInterno ?? this.esInterno,
    bd: bd ?? this.bd,
    siglaEmpresa: siglaEmpresa ?? this.siglaEmpresa,
    activo: activo ?? this.activo,
    audUsuario: audUsuario ?? this.audUsuario,
  );
}
