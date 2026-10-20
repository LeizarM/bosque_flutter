/// Estados de una fila según `p_list_tcpe_BancoLote` V. El texto lo trae SQL.
enum EstadoFilaImportacion {
  ok('OK'),
  duplicadaEnBanco('DUPLICADA_EN_BANCO'),
  duplicadaEnArchivo('DUPLICADA_EN_ARCHIVO'),
  error('ERROR');

  const EstadoFilaImportacion(this.codigo);

  final String codigo;

  /// Un código desconocido cuenta como error: nunca se importa a ciegas.
  static EstadoFilaImportacion desde(String? codigo) => values.firstWhere(
    (e) => e.codigo == (codigo ?? '').trim().toUpperCase(),
    orElse: () => EstadoFilaImportacion.error,
  );
}

/// Una fila de la vista previa de la importación (`p_list_tcpe_BancoLote` V).
class TcpeFilaImportacionEntity {
  final int fila;
  final String? pregunta;
  final bool esCerrada;
  final int cantOpciones;
  final int cantValidas;
  final EstadoFilaImportacion estado;
  final String? mensaje;
  final BigInt? codPreguntaExistente;

  const TcpeFilaImportacionEntity({
    required this.fila,
    this.pregunta,
    this.esCerrada = false,
    this.cantOpciones = 0,
    this.cantValidas = 0,
    this.estado = EstadoFilaImportacion.error,
    this.mensaje,
    this.codPreguntaExistente,
  });

  bool get importable => estado == EstadoFilaImportacion.ok;

  TcpeFilaImportacionEntity copyWith({
    int? fila,
    String? pregunta,
    bool? esCerrada,
    int? cantOpciones,
    int? cantValidas,
    EstadoFilaImportacion? estado,
    String? mensaje,
    BigInt? codPreguntaExistente,
  }) => TcpeFilaImportacionEntity(
    fila: fila ?? this.fila,
    pregunta: pregunta ?? this.pregunta,
    esCerrada: esCerrada ?? this.esCerrada,
    cantOpciones: cantOpciones ?? this.cantOpciones,
    cantValidas: cantValidas ?? this.cantValidas,
    estado: estado ?? this.estado,
    mensaje: mensaje ?? this.mensaje,
    codPreguntaExistente: codPreguntaExistente ?? this.codPreguntaExistente,
  );
}
