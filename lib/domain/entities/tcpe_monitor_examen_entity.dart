/// Un examen del lote en el panel "En vivo" (`p_list_tcpe_Monitor` L).
class TcpeMonitorExamenEntity {
  final BigInt codExamen;
  final String? login;
  final String? nombreCompleto;
  final String? ci;
  final String? estado;
  final DateTime? fechaInicio;
  final DateTime? fechaLimite;
  /// Al momento de la consulta: el panel sigue contando hasta la próxima.
  final int segundosRestantes;
  final int totalPreguntas;
  final int respondidas;
  /// La pregunta que está viendo (n de N); null si no abrió ninguna.
  final int? ordenActual;
  final DateTime? ultimaActividad;
  final int? segundosSinActividad;
  /// `CONECTADO`, `INACTIVO`, `DESCONECTADO` o `-` (no está en curso).
  final String? conexion;
  final int salidasPestana;
  final DateTime? ultimaSalida;
  final double? resultado;

  const TcpeMonitorExamenEntity({
    required this.codExamen,
    this.login,
    this.nombreCompleto,
    this.ci,
    this.estado,
    this.fechaInicio,
    this.fechaLimite,
    this.segundosRestantes = 0,
    this.totalPreguntas = 0,
    this.respondidas = 0,
    this.ordenActual,
    this.ultimaActividad,
    this.segundosSinActividad,
    this.conexion,
    this.salidasPestana = 0,
    this.ultimaSalida,
    this.resultado,
  });

  TcpeMonitorExamenEntity copyWith({
    BigInt? codExamen,
    String? login,
    String? nombreCompleto,
    String? ci,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaLimite,
    int? segundosRestantes,
    int? totalPreguntas,
    int? respondidas,
    int? ordenActual,
    DateTime? ultimaActividad,
    int? segundosSinActividad,
    String? conexion,
    int? salidasPestana,
    DateTime? ultimaSalida,
    double? resultado,
  }) => TcpeMonitorExamenEntity(
    codExamen: codExamen ?? this.codExamen,
    login: login ?? this.login,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    ci: ci ?? this.ci,
    estado: estado ?? this.estado,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaLimite: fechaLimite ?? this.fechaLimite,
    segundosRestantes: segundosRestantes ?? this.segundosRestantes,
    totalPreguntas: totalPreguntas ?? this.totalPreguntas,
    respondidas: respondidas ?? this.respondidas,
    ordenActual: ordenActual ?? this.ordenActual,
    ultimaActividad: ultimaActividad ?? this.ultimaActividad,
    segundosSinActividad: segundosSinActividad ?? this.segundosSinActividad,
    conexion: conexion ?? this.conexion,
    salidasPestana: salidasPestana ?? this.salidasPestana,
    ultimaSalida: ultimaSalida ?? this.ultimaSalida,
    resultado: resultado ?? this.resultado,
  );
}
