/// `tcpe_rsptaSemana` (v12): lo que un usuario de BOSQUE escribió en una
/// pregunta de la semana, una sola respuesta por persona. Columnas de
/// `p_list_tcpe_RsptaSemana` L más `nombreUsuario`.
class TcpeRsptaSemanaEntity {
  final BigInt codRsptaSemana;
  final BigInt? codPreguntaSemana;
  final BigInt? codUsuario;
  final String? respuesta;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRsptaSemanaEntity({
    required this.codRsptaSemana,
    this.codPreguntaSemana,
    this.codUsuario,
    this.respuesta,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRsptaSemanaEntity copyWith({
    BigInt? codRsptaSemana,
    BigInt? codPreguntaSemana,
    BigInt? codUsuario,
    String? respuesta,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRsptaSemanaEntity(
    codRsptaSemana: codRsptaSemana ?? this.codRsptaSemana,
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    codUsuario: codUsuario ?? this.codUsuario,
    respuesta: respuesta ?? this.respuesta,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
