/// Pregunta del banco con su categoría, área y respuesta (`p_list_tcpe_Banco` L).
class TcpeBancoPreguntaEntity {
  final BigInt codPregunta;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  final BigInt? codArea;
  final String? nombreArea;
  final String? pregunta;
  final int? prioridad;
  final bool activo;
  final BigInt? codRespuesta;
  final bool esCerrada;
  /// Respuesta modelo de una abierta.
  final String? respuesta;
  final int cantOpciones;
  final int cantValidas;
  /// En cuántos exámenes salió.
  final int usadaEnExamenes;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeBancoPreguntaEntity({
    required this.codPregunta,
    this.codClasificacion,
    this.nombreClasificacion,
    this.codArea,
    this.nombreArea,
    this.pregunta,
    this.prioridad,
    this.activo = true,
    this.codRespuesta,
    this.esCerrada = false,
    this.respuesta,
    this.cantOpciones = 0,
    this.cantValidas = 0,
    this.usadaEnExamenes = 0,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeBancoPreguntaEntity copyWith({
    BigInt? codPregunta,
    BigInt? codClasificacion,
    String? nombreClasificacion,
    BigInt? codArea,
    String? nombreArea,
    String? pregunta,
    int? prioridad,
    bool? activo,
    BigInt? codRespuesta,
    bool? esCerrada,
    String? respuesta,
    int? cantOpciones,
    int? cantValidas,
    int? usadaEnExamenes,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeBancoPreguntaEntity(
    codPregunta: codPregunta ?? this.codPregunta,
    codClasificacion: codClasificacion ?? this.codClasificacion,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    codArea: codArea ?? this.codArea,
    nombreArea: nombreArea ?? this.nombreArea,
    pregunta: pregunta ?? this.pregunta,
    prioridad: prioridad ?? this.prioridad,
    activo: activo ?? this.activo,
    codRespuesta: codRespuesta ?? this.codRespuesta,
    esCerrada: esCerrada ?? this.esCerrada,
    respuesta: respuesta ?? this.respuesta,
    cantOpciones: cantOpciones ?? this.cantOpciones,
    cantValidas: cantValidas ?? this.cantValidas,
    usadaEnExamenes: usadaEnExamenes ?? this.usadaEnExamenes,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );

  /// Ya salió en algún examen: no se borra, se desactiva.
  bool get usada => usadaEnExamenes > 0;
}
