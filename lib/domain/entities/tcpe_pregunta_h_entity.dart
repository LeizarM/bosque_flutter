/// `tcpe_preguntaH`: Foto de una pregunta tal como quedó en un examen generado.
/// Columnas de `p_list_tcpe_PreguntaH` (sin `password2`) más `nombreUsuario`.
class TcpePreguntaHEntity {
  final BigInt codPreguntaH;
  final BigInt? codPregunta;
  final BigInt? codClasificacion;
  final BigInt? codExamen;
  final String? pregunta;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpePreguntaHEntity({
    required this.codPreguntaH,
    this.codPregunta,
    this.codClasificacion,
    this.codExamen,
    this.pregunta,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpePreguntaHEntity copyWith({
    BigInt? codPreguntaH,
    BigInt? codPregunta,
    BigInt? codClasificacion,
    BigInt? codExamen,
    String? pregunta,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpePreguntaHEntity(
    codPreguntaH: codPreguntaH ?? this.codPreguntaH,
    codPregunta: codPregunta ?? this.codPregunta,
    codClasificacion: codClasificacion ?? this.codClasificacion,
    codExamen: codExamen ?? this.codExamen,
    pregunta: pregunta ?? this.pregunta,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
