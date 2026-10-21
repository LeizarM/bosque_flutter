/// Una pregunta del ranking de las más falladas de su categoría
/// (`p_list_tcpe_Resultado` P). Cuentan los exámenes rendidos; [fallos] se
/// reparte en [sinResponder], [incompletas] y los que eligieron una incorrecta.
class TcpeRankingPreguntaEntity {
  /// 1 = la más fallada de su categoría.
  final int puesto;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  final String? nombreArea;
  final BigInt codPregunta;
  final String? pregunta;
  final bool esCerrada;

  /// Veces que se calificó en exámenes rendidos.
  final int veces;
  final int aciertos;
  final int fallos;
  final int sinResponder;

  /// Marcó solo una parte de las correctas, sin ninguna incorrecta.
  final int incompletas;

  /// De 0 a 100, con un decimal.
  final double porcentajeFallo;

  /// La opción incorrecta más marcada; null si nadie eligió una incorrecta.
  final String? errorComun;
  final int vecesErrorComun;

  const TcpeRankingPreguntaEntity({
    required this.puesto,
    this.codClasificacion,
    this.nombreClasificacion,
    this.nombreArea,
    required this.codPregunta,
    this.pregunta,
    this.esCerrada = true,
    this.veces = 0,
    this.aciertos = 0,
    this.fallos = 0,
    this.sinResponder = 0,
    this.incompletas = 0,
    this.porcentajeFallo = 0,
    this.errorComun,
    this.vecesErrorComun = 0,
  });

  /// Los que eligieron alguna opción incorrecta (el resto de los fallos).
  int get conError {
    final n = fallos - sinResponder - incompletas;
    return n < 0 ? 0 : n;
  }

  TcpeRankingPreguntaEntity copyWith({
    int? puesto,
    BigInt? codClasificacion,
    String? nombreClasificacion,
    String? nombreArea,
    BigInt? codPregunta,
    String? pregunta,
    bool? esCerrada,
    int? veces,
    int? aciertos,
    int? fallos,
    int? sinResponder,
    int? incompletas,
    double? porcentajeFallo,
    String? errorComun,
    int? vecesErrorComun,
  }) => TcpeRankingPreguntaEntity(
    puesto: puesto ?? this.puesto,
    codClasificacion: codClasificacion ?? this.codClasificacion,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    nombreArea: nombreArea ?? this.nombreArea,
    codPregunta: codPregunta ?? this.codPregunta,
    pregunta: pregunta ?? this.pregunta,
    esCerrada: esCerrada ?? this.esCerrada,
    veces: veces ?? this.veces,
    aciertos: aciertos ?? this.aciertos,
    fallos: fallos ?? this.fallos,
    sinResponder: sinResponder ?? this.sinResponder,
    incompletas: incompletas ?? this.incompletas,
    porcentajeFallo: porcentajeFallo ?? this.porcentajeFallo,
    errorComun: errorComun ?? this.errorComun,
    vecesErrorComun: vecesErrorComun ?? this.vecesErrorComun,
  );
}
