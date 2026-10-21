/// Una pregunta de la semana vigente hoy para quien mira el inicio
/// (`p_list_tcpe_PreguntaSemana` V): abierta o de escala, lo que ya respondió y
/// la ayuda y el largo máximo. [mensaje] llega solo ya respondida.
class TcpePreguntaSemanaVigenteEntity {
  final BigInt codPreguntaSemana;

  /// Con el título de la configuración si la pregunta no tiene uno propio.
  final String? titulo;
  final String? pregunta;

  /// `A` abierta (un texto) o `E` escala (un número de [escalaMin] a [escalaMax]).
  final String tipo;
  final int? escalaMin;
  final int? escalaMax;

  /// Qué significan los extremos de la escala (opcionales).
  final String? etiquetaMin;
  final String? etiquetaMax;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasRestantes;
  final bool respondida;

  /// Lo que escribió quien mira en una abierta; null si todavía no respondió.
  final String? respuesta;

  /// El número que eligió quien mira en una de escala; null si todavía no respondió.
  final int? valor;
  final DateTime? fechaRespuesta;

  /// El agradecimiento que muestra el inicio después de responder (lo da el SP).
  final String? mensaje;

  /// La ayuda bajo la respuesta y el largo que acepta un texto (de la configuración).
  final String? ayuda;
  final int maxRespuesta;

  const TcpePreguntaSemanaVigenteEntity({
    required this.codPreguntaSemana,
    this.titulo,
    this.pregunta,
    this.tipo = 'A',
    this.escalaMin,
    this.escalaMax,
    this.etiquetaMin,
    this.etiquetaMax,
    this.fechaInicio,
    this.fechaFin,
    this.diasRestantes,
    this.respondida = false,
    this.respuesta,
    this.valor,
    this.fechaRespuesta,
    this.mensaje,
    this.ayuda,
    this.maxRespuesta = 500,
  });

  bool get esEscala => tipo.toUpperCase() == 'E';

  TcpePreguntaSemanaVigenteEntity copyWith({
    BigInt? codPreguntaSemana,
    String? titulo,
    String? pregunta,
    String? tipo,
    int? escalaMin,
    int? escalaMax,
    String? etiquetaMin,
    String? etiquetaMax,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? diasRestantes,
    bool? respondida,
    String? respuesta,
    int? valor,
    DateTime? fechaRespuesta,
    String? mensaje,
    String? ayuda,
    int? maxRespuesta,
  }) => TcpePreguntaSemanaVigenteEntity(
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    titulo: titulo ?? this.titulo,
    pregunta: pregunta ?? this.pregunta,
    tipo: tipo ?? this.tipo,
    escalaMin: escalaMin ?? this.escalaMin,
    escalaMax: escalaMax ?? this.escalaMax,
    etiquetaMin: etiquetaMin ?? this.etiquetaMin,
    etiquetaMax: etiquetaMax ?? this.etiquetaMax,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    diasRestantes: diasRestantes ?? this.diasRestantes,
    respondida: respondida ?? this.respondida,
    respuesta: respuesta ?? this.respuesta,
    valor: valor ?? this.valor,
    fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
    mensaje: mensaje ?? this.mensaje,
    ayuda: ayuda ?? this.ayuda,
    maxRespuesta: maxRespuesta ?? this.maxRespuesta,
  );
}
