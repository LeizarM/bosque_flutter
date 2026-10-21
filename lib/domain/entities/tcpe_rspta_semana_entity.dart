/// `tcpe_rsptaSemana` (v11): la respuesta de un usuario de BOSQUE a una pregunta
/// de la semana, una sola por persona. Columnas de `p_list_tcpe_RsptaSemana` L
/// más `nombreUsuario`. `esCorrecta` la calcula el SP al responder.
class TcpeRsptaSemanaEntity {
  final BigInt codRsptaSemana;
  final BigInt? codPreguntaSemana;
  final BigInt? codUsuario;
  final BigInt? codRsptaOp;
  final bool esCorrecta;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRsptaSemanaEntity({
    required this.codRsptaSemana,
    this.codPreguntaSemana,
    this.codUsuario,
    this.codRsptaOp,
    this.esCorrecta = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRsptaSemanaEntity copyWith({
    BigInt? codRsptaSemana,
    BigInt? codPreguntaSemana,
    BigInt? codUsuario,
    BigInt? codRsptaOp,
    bool? esCorrecta,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRsptaSemanaEntity(
    codRsptaSemana: codRsptaSemana ?? this.codRsptaSemana,
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    codUsuario: codUsuario ?? this.codUsuario,
    codRsptaOp: codRsptaOp ?? this.codRsptaOp,
    esCorrecta: esCorrecta ?? this.esCorrecta,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
