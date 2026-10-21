/// `tcpe_preguntaSemana` (v12/v13): una pregunta que se publica en el inicio con
/// su plazo, abierta («¿Qué tal tu día?») o de escala («Del 1 al 5…»). Columnas
/// de `p_list_tcpe_PreguntaSemana` L: la tabla, el estado de hoy y las respuestas.
class TcpePreguntaSemanaEntity {
  final BigInt codPreguntaSemana;
  final String? titulo;
  final String? pregunta;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;

  /// `A` abierta (se responde con un texto) o `E` escala (se elige un número).
  final String tipo;

  /// Solo escala: el primer y el último número, y qué significan (opcionales).
  final int? escalaMin;
  final int? escalaMax;
  final String? etiquetaMin;
  final String? etiquetaMax;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  /// Solo lectura, de la acción L: el título con el de la configuración si no tiene uno propio.
  final String? tituloMostrado;

  /// Solo lectura: «Abierta» o «Escala del 1 al 5», como lo arma el SP.
  final String? tipoMostrado;

  /// `VIGENTE`, `PROGRAMADA`, `TERMINADA` o `INACTIVA` (lo decide el SP con la fecha de hoy).
  final String? estado;
  final int respuestas;

  /// Solo escala: el promedio con un decimal; null si nadie respondió.
  final double? promedio;

  const TcpePreguntaSemanaEntity({
    required this.codPreguntaSemana,
    this.titulo,
    this.pregunta,
    this.fechaInicio,
    this.fechaFin,
    this.activo = true,
    this.tipo = 'A',
    this.escalaMin,
    this.escalaMax,
    this.etiquetaMin,
    this.etiquetaMax,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
    this.tituloMostrado,
    this.tipoMostrado,
    this.estado,
    this.respuestas = 0,
    this.promedio,
  });

  bool get esEscala => tipo.toUpperCase() == 'E';

  EstadoPreguntaSemana get estadoHoy => EstadoPreguntaSemana.desde(estado);

  TcpePreguntaSemanaEntity copyWith({
    BigInt? codPreguntaSemana,
    String? titulo,
    String? pregunta,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? activo,
    String? tipo,
    int? escalaMin,
    int? escalaMax,
    String? etiquetaMin,
    String? etiquetaMax,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
    String? tituloMostrado,
    String? tipoMostrado,
    String? estado,
    int? respuestas,
    double? promedio,
  }) => TcpePreguntaSemanaEntity(
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    titulo: titulo ?? this.titulo,
    pregunta: pregunta ?? this.pregunta,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    activo: activo ?? this.activo,
    tipo: tipo ?? this.tipo,
    escalaMin: escalaMin ?? this.escalaMin,
    escalaMax: escalaMax ?? this.escalaMax,
    etiquetaMin: etiquetaMin ?? this.etiquetaMin,
    etiquetaMax: etiquetaMax ?? this.etiquetaMax,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
    tituloMostrado: tituloMostrado ?? this.tituloMostrado,
    tipoMostrado: tipoMostrado ?? this.tipoMostrado,
    estado: estado ?? this.estado,
    respuestas: respuestas ?? this.respuestas,
    promedio: promedio ?? this.promedio,
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
