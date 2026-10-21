/// `tcpe_preguntaSemana` (v11): una pregunta cerrada del banco que se publica en
/// el inicio con su plazo. Columnas de `p_list_tcpe_PreguntaSemana` L: las de la
/// tabla más lo que agrega la gestión (pregunta, estado de hoy y aciertos).
class TcpePreguntaSemanaEntity {
  final BigInt codPreguntaSemana;
  final BigInt? codPregunta;
  final String? titulo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool mostrarRespuesta;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  // Solo lectura, de la acción L: el título con el de la configuración si no tiene uno propio.
  final String? tituloMostrado;
  final String? pregunta;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;

  /// `VIGENTE`, `PROGRAMADA`, `TERMINADA` o `INACTIVA` (lo decide el SP con la fecha de hoy).
  final String? estado;
  final int respuestas;
  final int correctas;
  final double? porcentajeAcierto;

  const TcpePreguntaSemanaEntity({
    required this.codPreguntaSemana,
    this.codPregunta,
    this.titulo,
    this.fechaInicio,
    this.fechaFin,
    this.mostrarRespuesta = true,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
    this.tituloMostrado,
    this.pregunta,
    this.codClasificacion,
    this.nombreClasificacion,
    this.estado,
    this.respuestas = 0,
    this.correctas = 0,
    this.porcentajeAcierto,
  });

  EstadoPreguntaSemana get estadoHoy => EstadoPreguntaSemana.desde(estado);

  TcpePreguntaSemanaEntity copyWith({
    BigInt? codPreguntaSemana,
    BigInt? codPregunta,
    String? titulo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? mostrarRespuesta,
    bool? activo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
    String? tituloMostrado,
    String? pregunta,
    BigInt? codClasificacion,
    String? nombreClasificacion,
    String? estado,
    int? respuestas,
    int? correctas,
    double? porcentajeAcierto,
  }) => TcpePreguntaSemanaEntity(
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    codPregunta: codPregunta ?? this.codPregunta,
    titulo: titulo ?? this.titulo,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    mostrarRespuesta: mostrarRespuesta ?? this.mostrarRespuesta,
    activo: activo ?? this.activo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
    tituloMostrado: tituloMostrado ?? this.tituloMostrado,
    pregunta: pregunta ?? this.pregunta,
    codClasificacion: codClasificacion ?? this.codClasificacion,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    estado: estado ?? this.estado,
    respuestas: respuestas ?? this.respuestas,
    correctas: correctas ?? this.correctas,
    porcentajeAcierto: porcentajeAcierto ?? this.porcentajeAcierto,
  );
}

/// El estado de hoy de una pregunta de la semana, tal como lo calcula el SP.
enum EstadoPreguntaSemana {
  vigente,
  programada,
  terminada,
  inactiva,
  desconocido;

  static EstadoPreguntaSemana desde(String? codigo) => switch ((codigo ?? '').trim().toUpperCase()) {
    'VIGENTE' => vigente,
    'PROGRAMADA' => programada,
    'TERMINADA' => terminada,
    'INACTIVA' => inactiva,
    _ => desconocido,
  };
}
