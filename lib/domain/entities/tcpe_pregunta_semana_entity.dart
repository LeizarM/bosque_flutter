/// `tcpe_preguntaSemana` (v12): una pregunta libre («¿Qué tal tu día?») que se
/// publica en el inicio con su plazo. Columnas de `p_list_tcpe_PreguntaSemana` L:
/// las de la tabla más el estado de hoy y cuántos respondieron.
class TcpePreguntaSemanaEntity {
  final BigInt codPreguntaSemana;
  final String? titulo;
  final String? pregunta;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  /// Solo lectura, de la acción L: el título con el de la configuración si no tiene uno propio.
  final String? tituloMostrado;

  /// `VIGENTE`, `PROGRAMADA`, `TERMINADA` o `INACTIVA` (lo decide el SP con la fecha de hoy).
  final String? estado;
  final int respuestas;

  const TcpePreguntaSemanaEntity({
    required this.codPreguntaSemana,
    this.titulo,
    this.pregunta,
    this.fechaInicio,
    this.fechaFin,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
    this.tituloMostrado,
    this.estado,
    this.respuestas = 0,
  });

  EstadoPreguntaSemana get estadoHoy => EstadoPreguntaSemana.desde(estado);

  TcpePreguntaSemanaEntity copyWith({
    BigInt? codPreguntaSemana,
    String? titulo,
    String? pregunta,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? activo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
    String? tituloMostrado,
    String? estado,
    int? respuestas,
  }) => TcpePreguntaSemanaEntity(
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    titulo: titulo ?? this.titulo,
    pregunta: pregunta ?? this.pregunta,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    activo: activo ?? this.activo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
    tituloMostrado: tituloMostrado ?? this.tituloMostrado,
    estado: estado ?? this.estado,
    respuestas: respuestas ?? this.respuestas,
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
