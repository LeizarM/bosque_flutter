/// Tramo de comision segun los dias que tardo el cliente en pagar
/// (tabla tcom_comisionPorRango). Lo usa la modalidad dinamica vigente.
///
/// OJO con la escala: [comision] esta en BASE 1, o sea 0.008 es 0,8%. En los
/// grupos el porcentaje esta en puntos porcentuales, donde 0.7 es 0,7%. Son dos
/// convenciones distintas en el mismo modulo; [comisionVisual] ya viene
/// convertida por el backend.
class ComisionPorRangoEntity {
  final BigInt idCfr;

  /// Base 1. Para 0,8% vale 0.008.
  final double comision;

  /// El mismo valor en puntos porcentuales, listo para mostrar.
  final double comisionVisual;

  /// Dia inicial del tramo. Negativo significa pago anticipado.
  final int min;

  /// Dia final del tramo.
  final int max;

  /// Contado o Credito.
  final String tipo;

  final int esInterno;
  final BigInt audUsuario;

  const ComisionPorRangoEntity({
    required this.idCfr,
    required this.comision,
    required this.comisionVisual,
    required this.min,
    required this.max,
    required this.tipo,
    required this.esInterno,
    required this.audUsuario,
  });

  /// Tramo de pago anticipado: el cliente paga antes del vencimiento.
  bool get esAnticipado => max < 0;

  /// Tramo abierto por la derecha, sin tope real de dias.
  bool get sinTope => max >= 1000000;

  /// Rango legible. Evita mostrar los centinelas -999999999 y 1000000.
  String get rangoLegible {
    if (esAnticipado) return 'Pago anticipado';
    if (sinTope) return 'Desde $min dias';
    return '$min a $max dias';
  }

  ComisionPorRangoEntity copyWith({
    BigInt? idCfr,
    double? comision,
    double? comisionVisual,
    int? min,
    int? max,
    String? tipo,
    int? esInterno,
    BigInt? audUsuario,
  }) => ComisionPorRangoEntity(
    idCfr: idCfr ?? this.idCfr,
    comision: comision ?? this.comision,
    comisionVisual: comisionVisual ?? this.comisionVisual,
    min: min ?? this.min,
    max: max ?? this.max,
    tipo: tipo ?? this.tipo,
    esInterno: esInterno ?? this.esInterno,
    audUsuario: audUsuario ?? this.audUsuario,
  );
}
