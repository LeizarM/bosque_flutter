/// `tcpe_rolExamen`: Lote de exámenes: categoría, duración, cantidad de preguntas y fecha.
/// Columnas de `p_list_tcpe_RolExamen` (sin `password2`) más `nombreUsuario`.
class TcpeRolExamenEntity {
  final BigInt codRolExamen;
  final BigInt? codCapacitacion;
  final BigInt? codConvocatoria;
  final BigInt? codArea;
  final int? ponderacion;
  final int? puntos;
  final int? duracionMinutos;
  final int? cantidadPreg;
  final int? cantExamenGenerar;
  final String? ubicacion;
  final String? modalidad;
  final bool? esRolCapacitacion;
  final DateTime? fecha;
  final String? horaInicio;
  final String? horaFin;
  final BigInt? codClasificacion;
  final String? titulo;
  final String? observaciones;
  final double? notaAprobacion;
  final bool? mostrarRespuestas;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRolExamenEntity({
    required this.codRolExamen,
    this.codCapacitacion,
    this.codConvocatoria,
    this.codArea,
    this.ponderacion,
    this.puntos,
    this.duracionMinutos,
    this.cantidadPreg,
    this.cantExamenGenerar,
    this.ubicacion,
    this.modalidad,
    this.esRolCapacitacion,
    this.fecha,
    this.horaInicio,
    this.horaFin,
    this.codClasificacion,
    this.titulo,
    this.observaciones,
    this.notaAprobacion,
    this.mostrarRespuestas,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRolExamenEntity copyWith({
    BigInt? codRolExamen,
    BigInt? codCapacitacion,
    BigInt? codConvocatoria,
    BigInt? codArea,
    int? ponderacion,
    int? puntos,
    int? duracionMinutos,
    int? cantidadPreg,
    int? cantExamenGenerar,
    String? ubicacion,
    String? modalidad,
    bool? esRolCapacitacion,
    DateTime? fecha,
    String? horaInicio,
    String? horaFin,
    BigInt? codClasificacion,
    String? titulo,
    String? observaciones,
    double? notaAprobacion,
    bool? mostrarRespuestas,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRolExamenEntity(
    codRolExamen: codRolExamen ?? this.codRolExamen,
    codCapacitacion: codCapacitacion ?? this.codCapacitacion,
    codConvocatoria: codConvocatoria ?? this.codConvocatoria,
    codArea: codArea ?? this.codArea,
    ponderacion: ponderacion ?? this.ponderacion,
    puntos: puntos ?? this.puntos,
    duracionMinutos: duracionMinutos ?? this.duracionMinutos,
    cantidadPreg: cantidadPreg ?? this.cantidadPreg,
    cantExamenGenerar: cantExamenGenerar ?? this.cantExamenGenerar,
    ubicacion: ubicacion ?? this.ubicacion,
    modalidad: modalidad ?? this.modalidad,
    esRolCapacitacion: esRolCapacitacion ?? this.esRolCapacitacion,
    fecha: fecha ?? this.fecha,
    horaInicio: horaInicio ?? this.horaInicio,
    horaFin: horaFin ?? this.horaFin,
    codClasificacion: codClasificacion ?? this.codClasificacion,
    titulo: titulo ?? this.titulo,
    observaciones: observaciones ?? this.observaciones,
    notaAprobacion: notaAprobacion ?? this.notaAprobacion,
    mostrarRespuestas: mostrarRespuestas ?? this.mostrarRespuestas,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
