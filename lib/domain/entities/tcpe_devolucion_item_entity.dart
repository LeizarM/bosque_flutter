/// Una fila de la devolución de un examen entregado (`p_list_tcpe_Rendir` F):
/// una por opción de cada cerrada y una sola, con la opción en null, por
/// abierta. [esValido] es null si el lote no muestra las respuestas.
class TcpeDevolucionItemEntity {
  final BigInt codPreguntaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;

  /// De la pregunta, no de la opción. Null = abierta sin calificar.
  final bool? esCorrecta;
  final String? respuestaU;
  final BigInt? codRsptaOpH;
  final String? opcionRspta;
  final bool marcada;
  final bool? esValido;

  const TcpeDevolucionItemEntity({
    required this.codPreguntaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.esCorrecta,
    this.respuestaU,
    this.codRsptaOpH,
    this.opcionRspta,
    this.marcada = false,
    this.esValido,
  });

  TcpeDevolucionItemEntity copyWith({
    BigInt? codPreguntaH,
    int? orden,
    String? pregunta,
    bool? esCerrada,
    bool? esCorrecta,
    String? respuestaU,
    BigInt? codRsptaOpH,
    String? opcionRspta,
    bool? marcada,
    bool? esValido,
  }) => TcpeDevolucionItemEntity(
    codPreguntaH: codPreguntaH ?? this.codPreguntaH,
    orden: orden ?? this.orden,
    pregunta: pregunta ?? this.pregunta,
    esCerrada: esCerrada ?? this.esCerrada,
    esCorrecta: esCorrecta ?? this.esCorrecta,
    respuestaU: respuestaU ?? this.respuestaU,
    codRsptaOpH: codRsptaOpH ?? this.codRsptaOpH,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    marcada: marcada ?? this.marcada,
    esValido: esValido ?? this.esValido,
  );
}

/// Una pregunta de la devolución con sus opciones, armada desde las filas.
class TcpeDevolucionPreguntaEntity {
  final BigInt codPreguntaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;
  final bool? esCorrecta;
  final String? respuestaU;

  /// Solo las cerradas; en el orden en que llegaron.
  final List<TcpeDevolucionItemEntity> opciones;

  const TcpeDevolucionPreguntaEntity({
    required this.codPreguntaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.esCorrecta,
    this.respuestaU,
    this.opciones = const [],
  });

  /// Abierta que el evaluador todavía no calificó (o cerrada sin nota).
  bool get pendiente => esCorrecta == null;

  /// El lote deja ver cuáles eran las correctas.
  bool get muestraCorrectas => opciones.any((o) => o.esValido != null);

  bool get respondida =>
      esCerrada ? opciones.any((o) => o.marcada) : (respuestaU ?? '').trim().isNotEmpty;

  /// Agrupa por `codPreguntaH`, ordenadas por `orden`.
  static List<TcpeDevolucionPreguntaEntity> agrupar(List<TcpeDevolucionItemEntity> filas) {
    final porPregunta = <BigInt, List<TcpeDevolucionItemEntity>>{};
    for (final f in filas) {
      porPregunta.putIfAbsent(f.codPreguntaH, () => []).add(f);
    }
    final preguntas = [
      for (final grupo in porPregunta.values)
        TcpeDevolucionPreguntaEntity(
          codPreguntaH: grupo.first.codPreguntaH,
          orden: grupo.first.orden,
          pregunta: grupo.first.pregunta,
          esCerrada: grupo.first.esCerrada,
          esCorrecta: grupo.first.esCorrecta,
          respuestaU: grupo.first.respuestaU,
          opciones: [
            for (final f in grupo)
              if (f.codRsptaOpH != null) f,
          ],
        ),
    ];
    return preguntas..sort((a, b) {
      final o = a.orden.compareTo(b.orden);
      return o != 0 ? o : a.codPreguntaH.compareTo(b.codPreguntaH);
    });
  }
}
