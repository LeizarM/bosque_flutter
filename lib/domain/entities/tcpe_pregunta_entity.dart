/// `tcpe_pregunta`: Pregunta del banco.
/// Columnas de `p_list_tcpe_Pregunta` (sin `password2`) más `nombreUsuario`.
class TcpePreguntaEntity {
  final BigInt codPregunta;
  final BigInt? codClasificacion;
  final int? prioridad;
  final String? pregunta;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpePreguntaEntity({
    required this.codPregunta,
    this.codClasificacion,
    this.prioridad,
    this.pregunta,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpePreguntaEntity copyWith({
    BigInt? codPregunta,
    BigInt? codClasificacion,
    int? prioridad,
    String? pregunta,
    bool? activo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpePreguntaEntity(
    codPregunta: codPregunta ?? this.codPregunta,
    codClasificacion: codClasificacion ?? this.codClasificacion,
    prioridad: prioridad ?? this.prioridad,
    pregunta: pregunta ?? this.pregunta,
    activo: activo ?? this.activo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
