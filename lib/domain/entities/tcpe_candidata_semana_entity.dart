/// Una pregunta del banco para elegir como pregunta de la semana
/// (`p_list_tcpe_PreguntaSemana` B). Si no se puede, [motivo] dice por qué
/// (lo decide `f_tcpe_motivoSemana`).
class TcpeCandidataSemanaEntity {
  final BigInt codPregunta;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  final String? nombreArea;
  final String? pregunta;
  final int cantOpciones;
  final int cantValidas;
  final bool puedeElegirse;
  final String? motivo;

  /// Cuántas preguntas de la semana ya la usaron.
  final int vecesUsada;

  const TcpeCandidataSemanaEntity({
    required this.codPregunta,
    this.codClasificacion,
    this.nombreClasificacion,
    this.nombreArea,
    this.pregunta,
    this.cantOpciones = 0,
    this.cantValidas = 0,
    this.puedeElegirse = false,
    this.motivo,
    this.vecesUsada = 0,
  });

  TcpeCandidataSemanaEntity copyWith({
    BigInt? codPregunta,
    BigInt? codClasificacion,
    String? nombreClasificacion,
    String? nombreArea,
    String? pregunta,
    int? cantOpciones,
    int? cantValidas,
    bool? puedeElegirse,
    String? motivo,
    int? vecesUsada,
  }) => TcpeCandidataSemanaEntity(
    codPregunta: codPregunta ?? this.codPregunta,
    codClasificacion: codClasificacion ?? this.codClasificacion,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    nombreArea: nombreArea ?? this.nombreArea,
    pregunta: pregunta ?? this.pregunta,
    cantOpciones: cantOpciones ?? this.cantOpciones,
    cantValidas: cantValidas ?? this.cantValidas,
    puedeElegirse: puedeElegirse ?? this.puedeElegirse,
    motivo: motivo ?? this.motivo,
    vecesUsada: vecesUsada ?? this.vecesUsada,
  );
}
