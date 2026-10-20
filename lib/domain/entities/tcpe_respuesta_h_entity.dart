/// `tcpe_respuestaH`: Foto de la respuesta en un examen, con lo que contestó el usuario.
/// Columnas de `p_list_tcpe_RespuestaH` (sin `password2`) más `nombreUsuario`.
class TcpeRespuestaHEntity {
  final BigInt codRespuestaH;
  final BigInt? codPreguntaH;
  final BigInt? codPregunta;
  final BigInt? codRespuesta;
  final String? respuesta;
  final String? respuestaU;
  final bool esCerrada;
  final bool? esCorrecta;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRespuestaHEntity({
    required this.codRespuestaH,
    this.codPreguntaH,
    this.codPregunta,
    this.codRespuesta,
    this.respuesta,
    this.respuestaU,
    this.esCerrada = false,
    this.esCorrecta,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRespuestaHEntity copyWith({
    BigInt? codRespuestaH,
    BigInt? codPreguntaH,
    BigInt? codPregunta,
    BigInt? codRespuesta,
    String? respuesta,
    String? respuestaU,
    bool? esCerrada,
    bool? esCorrecta,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRespuestaHEntity(
    codRespuestaH: codRespuestaH ?? this.codRespuestaH,
    codPreguntaH: codPreguntaH ?? this.codPreguntaH,
    codPregunta: codPregunta ?? this.codPregunta,
    codRespuesta: codRespuesta ?? this.codRespuesta,
    respuesta: respuesta ?? this.respuesta,
    respuestaU: respuestaU ?? this.respuestaU,
    esCerrada: esCerrada ?? this.esCerrada,
    esCorrecta: esCorrecta ?? this.esCorrecta,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
