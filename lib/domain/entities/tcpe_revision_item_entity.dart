/// Una pregunta de un examen entregado, para revisarla (`p_list_tcpe_Resultado` R).
class TcpeRevisionItemEntity {
  final BigInt codPreguntaH;
  final BigInt? codRespuestaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;
  final String? respuestaModelo;
  final String? respuestaU;
  final bool? esCorrecta;
  /// Textos de las opciones marcadas unidos con `' | '`.
  final String? marcadas;
  /// Textos de las opciones válidas unidos con `' | '`.
  final String? correctas;

  const TcpeRevisionItemEntity({
    required this.codPreguntaH,
    this.codRespuestaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.respuestaModelo,
    this.respuestaU,
    this.esCorrecta,
    this.marcadas,
    this.correctas,
  });

  TcpeRevisionItemEntity copyWith({
    BigInt? codPreguntaH,
    BigInt? codRespuestaH,
    int? orden,
    String? pregunta,
    bool? esCerrada,
    String? respuestaModelo,
    String? respuestaU,
    bool? esCorrecta,
    String? marcadas,
    String? correctas,
  }) => TcpeRevisionItemEntity(
    codPreguntaH: codPreguntaH ?? this.codPreguntaH,
    codRespuestaH: codRespuestaH ?? this.codRespuestaH,
    orden: orden ?? this.orden,
    pregunta: pregunta ?? this.pregunta,
    esCerrada: esCerrada ?? this.esCerrada,
    respuestaModelo: respuestaModelo ?? this.respuestaModelo,
    respuestaU: respuestaU ?? this.respuestaU,
    esCorrecta: esCorrecta ?? this.esCorrecta,
    marcadas: marcadas ?? this.marcadas,
    correctas: correctas ?? this.correctas,
  );

  /// Abierta que el evaluador todavía no marcó.
  bool get pendiente => !esCerrada && esCorrecta == null;
}
