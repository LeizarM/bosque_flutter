/// Lote de exámenes con su avance (`p_list_tcpe_Lote` L).
class TcpeLoteEntity {
  final BigInt codRolExamen;
  final String? titulo;
  final String? observaciones;
  final BigInt? codArea;
  final String? nombreArea;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  /// `O` online o `E` escrito.
  final String? modalidad;
  final int? duracionMinutos;
  final int? cantidadPreg;
  final int? cantExamenGenerar;
  final DateTime? fecha;
  /// `HH:mm:ss`.
  final String? horaInicio;
  final String? horaFin;
  final String? ubicacion;
  final int examenes;
  final int sinIniciar;
  final int enCurso;
  /// Pasaron su hora límite sin entregarse; se entregan al listar resultados.
  final int vencidos;
  final int porRevisar;
  final int calificados;
  /// No empezaron dentro de la ventana: cuentan como reprobados.
  final int ausentes;
  /// `fecha + horaInicio` y `fecha + horaFin`; null si faltan.
  final DateTime? inicioVentana;
  final DateTime? finVentana;
  final double? promedio;
  /// Nota mínima para aprobar (0 a 100); el backend usa 51 si no se indica.
  final double? notaAprobacion;
  /// Al terminar, quien rindió ve cuáles eran las correctas.
  final bool? mostrarRespuestas;
  /// Calificados con `resultado >= notaAprobacion` y los demás calificados.
  final int aprobados;
  final int reprobados;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeLoteEntity({
    required this.codRolExamen,
    this.titulo,
    this.observaciones,
    this.codArea,
    this.nombreArea,
    this.codClasificacion,
    this.nombreClasificacion,
    this.modalidad,
    this.duracionMinutos,
    this.cantidadPreg,
    this.cantExamenGenerar,
    this.fecha,
    this.horaInicio,
    this.horaFin,
    this.ubicacion,
    this.examenes = 0,
    this.sinIniciar = 0,
    this.enCurso = 0,
    this.vencidos = 0,
    this.porRevisar = 0,
    this.calificados = 0,
    this.ausentes = 0,
    this.inicioVentana,
    this.finVentana,
    this.promedio,
    this.notaAprobacion,
    this.mostrarRespuestas,
    this.aprobados = 0,
    this.reprobados = 0,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeLoteEntity copyWith({
    BigInt? codRolExamen,
    String? titulo,
    String? observaciones,
    BigInt? codArea,
    String? nombreArea,
    BigInt? codClasificacion,
    String? nombreClasificacion,
    String? modalidad,
    int? duracionMinutos,
    int? cantidadPreg,
    int? cantExamenGenerar,
    DateTime? fecha,
    String? horaInicio,
    String? horaFin,
    String? ubicacion,
    int? examenes,
    int? sinIniciar,
    int? enCurso,
    int? vencidos,
    int? porRevisar,
    int? calificados,
    int? ausentes,
    DateTime? inicioVentana,
    DateTime? finVentana,
    double? promedio,
    double? notaAprobacion,
    bool? mostrarRespuestas,
    int? aprobados,
    int? reprobados,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeLoteEntity(
    codRolExamen: codRolExamen ?? this.codRolExamen,
    titulo: titulo ?? this.titulo,
    observaciones: observaciones ?? this.observaciones,
    codArea: codArea ?? this.codArea,
    nombreArea: nombreArea ?? this.nombreArea,
    codClasificacion: codClasificacion ?? this.codClasificacion,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    modalidad: modalidad ?? this.modalidad,
    duracionMinutos: duracionMinutos ?? this.duracionMinutos,
    cantidadPreg: cantidadPreg ?? this.cantidadPreg,
    cantExamenGenerar: cantExamenGenerar ?? this.cantExamenGenerar,
    fecha: fecha ?? this.fecha,
    horaInicio: horaInicio ?? this.horaInicio,
    horaFin: horaFin ?? this.horaFin,
    ubicacion: ubicacion ?? this.ubicacion,
    examenes: examenes ?? this.examenes,
    sinIniciar: sinIniciar ?? this.sinIniciar,
    enCurso: enCurso ?? this.enCurso,
    vencidos: vencidos ?? this.vencidos,
    porRevisar: porRevisar ?? this.porRevisar,
    calificados: calificados ?? this.calificados,
    ausentes: ausentes ?? this.ausentes,
    inicioVentana: inicioVentana ?? this.inicioVentana,
    finVentana: finVentana ?? this.finVentana,
    promedio: promedio ?? this.promedio,
    notaAprobacion: notaAprobacion ?? this.notaAprobacion,
    mostrarRespuestas: mostrarRespuestas ?? this.mostrarRespuestas,
    aprobados: aprobados ?? this.aprobados,
    reprobados: reprobados ?? this.reprobados,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );

  /// `O` se rinde en el sistema; `E` se imprime y se rinde en papel.
  bool get esOnline => modalidad != 'E';

  /// Ya hay exámenes empezados: la duración queda fija.
  bool get algunoIniciado => examenes > sinIniciar;
}
