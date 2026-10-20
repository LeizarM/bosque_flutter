/// Pregunta de un examen en curso (`p_list_tcpe_Rendir` P).
class TcpePreguntaRendicionEntity {
  final BigInt codPreguntaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;
  final BigInt? codRespuestaH;
  final String? respuestaU;
  final bool respondida;

  const TcpePreguntaRendicionEntity({
    required this.codPreguntaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.codRespuestaH,
    this.respuestaU,
    this.respondida = false,
  });

  TcpePreguntaRendicionEntity copyWith({
    BigInt? codPreguntaH,
    int? orden,
    String? pregunta,
    bool? esCerrada,
    BigInt? codRespuestaH,
    String? respuestaU,
    bool? respondida,
  }) => TcpePreguntaRendicionEntity(
    codPreguntaH: codPreguntaH ?? this.codPreguntaH,
    orden: orden ?? this.orden,
    pregunta: pregunta ?? this.pregunta,
    esCerrada: esCerrada ?? this.esCerrada,
    codRespuestaH: codRespuestaH ?? this.codRespuestaH,
    respuestaU: respuestaU ?? this.respuestaU,
    respondida: respondida ?? this.respondida,
  );
}
