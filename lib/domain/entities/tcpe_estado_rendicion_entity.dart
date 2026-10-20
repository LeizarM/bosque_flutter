import 'package:bosque_flutter/domain/entities/tcpe_estado_examen.dart';

/// Estado de un examen para quien lo rinde (`p_list_tcpe_Rendir` M y E).
class TcpeEstadoRendicionEntity {
  final BigInt codExamen;
  final BigInt? codRolExamen;
  final String? titulo;
  final String? nombreClasificacion;
  final String? modalidad;
  final int duracionMinutos;
  final int totalPreguntas;
  final int respondidas;
  final String? estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? fechaLimite;
  /// Lo calcula el servidor: es la base del cronómetro.
  final int segundosRestantes;
  /// Solo viene con el estado `CALIFICADO`.
  final double? resultado;
  /// Nota mínima del lote para aprobar.
  final double? notaAprobacion;
  /// Solo viene con el examen calificado.
  final bool? aprobado;
  /// El lote deja ver las correctas al terminar.
  final bool? mostrarRespuestas;
  /// El texto de cada estado, tal como sale de SQL: se muestra sin cambios.
  final String? mensajeEstado;
  /// Ventana del lote (`fecha + horaInicio` y `fecha + horaFin`); null = sin límite.
  final DateTime? inicioVentana;
  final DateTime? finVentana;

  const TcpeEstadoRendicionEntity({
    required this.codExamen,
    this.codRolExamen,
    this.titulo,
    this.nombreClasificacion,
    this.modalidad,
    this.duracionMinutos = 0,
    this.totalPreguntas = 0,
    this.respondidas = 0,
    this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.fechaLimite,
    this.segundosRestantes = 0,
    this.resultado,
    this.notaAprobacion,
    this.aprobado,
    this.mostrarRespuestas,
    this.mensajeEstado,
    this.inicioVentana,
    this.finVentana,
  });

  TcpeEstadoRendicionEntity copyWith({
    BigInt? codExamen,
    BigInt? codRolExamen,
    String? titulo,
    String? nombreClasificacion,
    String? modalidad,
    int? duracionMinutos,
    int? totalPreguntas,
    int? respondidas,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    DateTime? fechaLimite,
    int? segundosRestantes,
    double? resultado,
    double? notaAprobacion,
    bool? aprobado,
    bool? mostrarRespuestas,
    String? mensajeEstado,
    DateTime? inicioVentana,
    DateTime? finVentana,
  }) => TcpeEstadoRendicionEntity(
    codExamen: codExamen ?? this.codExamen,
    codRolExamen: codRolExamen ?? this.codRolExamen,
    titulo: titulo ?? this.titulo,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    modalidad: modalidad ?? this.modalidad,
    duracionMinutos: duracionMinutos ?? this.duracionMinutos,
    totalPreguntas: totalPreguntas ?? this.totalPreguntas,
    respondidas: respondidas ?? this.respondidas,
    estado: estado ?? this.estado,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    fechaLimite: fechaLimite ?? this.fechaLimite,
    segundosRestantes: segundosRestantes ?? this.segundosRestantes,
    resultado: resultado ?? this.resultado,
    notaAprobacion: notaAprobacion ?? this.notaAprobacion,
    aprobado: aprobado ?? this.aprobado,
    mostrarRespuestas: mostrarRespuestas ?? this.mostrarRespuestas,
    mensajeEstado: mensajeEstado ?? this.mensajeEstado,
    inicioVentana: inicioVentana ?? this.inicioVentana,
    finVentana: finVentana ?? this.finVentana,
  );

  /// Los escritos (`E`) aparecen en la lista pero no se rinden en línea.
  bool get esOnline => modalidad != 'E';

  /// La nota que se le muestra: nunca mientras espera la revisión.
  double? get notaVisible => EstadoExamenTcpe.desde(estado) == EstadoExamenTcpe.porRevisar ? null : resultado;

  /// El `aprobado` que decide SQL; null mientras no haya nota visible.
  bool? get aprobacion => notaVisible == null ? null : aprobado;
}
