/// Escala de comision dinamica por meta (tabla tcom_ComisionDinamica).
///
/// La vigencia permite recalcular un periodo cerrado con las metas que regian
/// en ese momento, no con las actuales.
class ComisionDinamicaEntity {
  final BigInt idDc;
  final int esInterno;
  final double metaUsd;
  final double metaBs;
  final double porcentaje;
  final DateTime vigenteDesde;
  final DateTime? vigenteHasta;
  final BigInt audUsuario;

  const ComisionDinamicaEntity({
    required this.idDc,
    required this.esInterno,
    required this.metaUsd,
    required this.metaBs,
    required this.porcentaje,
    required this.vigenteDesde,
    this.vigenteHasta,
    required this.audUsuario,
  });

  double get porcentajeVisual => porcentaje;

  bool get esVigente =>
      vigenteHasta == null || !vigenteHasta!.isBefore(DateTime.now());

  ComisionDinamicaEntity copyWith({
    BigInt? idDc,
    int? esInterno,
    double? metaUsd,
    double? metaBs,
    double? porcentaje,
    DateTime? vigenteDesde,
    DateTime? vigenteHasta,
    BigInt? audUsuario,
  }) => ComisionDinamicaEntity(
    idDc: idDc ?? this.idDc,
    esInterno: esInterno ?? this.esInterno,
    metaUsd: metaUsd ?? this.metaUsd,
    metaBs: metaBs ?? this.metaBs,
    porcentaje: porcentaje ?? this.porcentaje,
    vigenteDesde: vigenteDesde ?? this.vigenteDesde,
    vigenteHasta: vigenteHasta ?? this.vigenteHasta,
    audUsuario: audUsuario ?? this.audUsuario,
  );
}
