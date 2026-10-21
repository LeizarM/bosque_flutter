/// Una pregunta de la semana vigente hoy para quien mira el inicio
/// (`p_list_tcpe_PreguntaSemana` V): lo que ya respondió y, para el campo de
/// texto, la ayuda y el largo máximo. [mensaje] llega solo ya respondida.
class TcpePreguntaSemanaVigenteEntity {
  final BigInt codPreguntaSemana;

  /// Con el título de la configuración si la pregunta no tiene uno propio.
  final String? titulo;
  final String? pregunta;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasRestantes;
  final bool respondida;

  /// Lo que escribió quien mira; null si todavía no respondió.
  final String? respuesta;
  final DateTime? fechaRespuesta;

  /// El agradecimiento que muestra el inicio después de responder (lo da el SP).
  final String? mensaje;

  /// La ayuda bajo el campo de texto y el largo que acepta (de la configuración).
  final String? ayuda;
  final int maxRespuesta;

  const TcpePreguntaSemanaVigenteEntity({
    required this.codPreguntaSemana,
    this.titulo,
    this.pregunta,
    this.fechaInicio,
    this.fechaFin,
    this.diasRestantes,
    this.respondida = false,
    this.respuesta,
    this.fechaRespuesta,
    this.mensaje,
    this.ayuda,
    this.maxRespuesta = 500,
  });

  TcpePreguntaSemanaVigenteEntity copyWith({
    BigInt? codPreguntaSemana,
    String? titulo,
    String? pregunta,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? diasRestantes,
    bool? respondida,
    String? respuesta,
    DateTime? fechaRespuesta,
    String? mensaje,
    String? ayuda,
    int? maxRespuesta,
  }) => TcpePreguntaSemanaVigenteEntity(
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    titulo: titulo ?? this.titulo,
    pregunta: pregunta ?? this.pregunta,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    diasRestantes: diasRestantes ?? this.diasRestantes,
    respondida: respondida ?? this.respondida,
    respuesta: respuesta ?? this.respuesta,
    fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
    mensaje: mensaje ?? this.mensaje,
    ayuda: ayuda ?? this.ayuda,
    maxRespuesta: maxRespuesta ?? this.maxRespuesta,
  );
}
