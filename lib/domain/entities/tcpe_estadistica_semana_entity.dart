/// Cuántos eligieron una opción de una pregunta de la semana
/// (`p_list_tcpe_PreguntaSemana` E). Vienen también las que nadie eligió.
class TcpeEstadisticaSemanaEntity {
  final BigInt codRsptaOp;
  final String? opcionRspta;
  final bool esValido;
  final int veces;

  /// Porcentaje de las respuestas, de 0 a 100 con un decimal.
  final double porcentaje;

  const TcpeEstadisticaSemanaEntity({
    required this.codRsptaOp,
    this.opcionRspta,
    this.esValido = false,
    this.veces = 0,
    this.porcentaje = 0,
  });

  TcpeEstadisticaSemanaEntity copyWith({
    BigInt? codRsptaOp,
    String? opcionRspta,
    bool? esValido,
    int? veces,
    double? porcentaje,
  }) => TcpeEstadisticaSemanaEntity(
    codRsptaOp: codRsptaOp ?? this.codRsptaOp,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    esValido: esValido ?? this.esValido,
    veces: veces ?? this.veces,
    porcentaje: porcentaje ?? this.porcentaje,
  );
}
