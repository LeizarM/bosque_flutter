import 'package:bosque_flutter/domain/entities/tcpe_opcion_semana_entity.dart';

/// Una pregunta de la semana vigente hoy para quien mira el inicio
/// (`/examenes/pregunta-semana/vigentes`: `p_list_tcpe_PreguntaSemana` V con
/// sus opciones de O). El resultado y su [mensaje] llegan solo si ya respondió.
class TcpePreguntaSemanaVigenteEntity {
  final BigInt codPreguntaSemana;

  /// Con el título de la configuración si la pregunta no tiene uno propio.
  final String? titulo;
  final String? pregunta;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasRestantes;
  final bool mostrarRespuesta;
  final bool respondida;
  final BigInt? codRsptaOpElegida;
  final bool? esCorrecta;
  final String? respuestaCorrecta;

  /// El texto que muestra el inicio después de responder (lo arma el SP).
  final String? mensaje;

  /// Cuántas personas respondieron.
  final int respuestas;
  final List<TcpeOpcionSemanaEntity> opciones;

  const TcpePreguntaSemanaVigenteEntity({
    required this.codPreguntaSemana,
    this.titulo,
    this.pregunta,
    this.fechaInicio,
    this.fechaFin,
    this.diasRestantes,
    this.mostrarRespuesta = true,
    this.respondida = false,
    this.codRsptaOpElegida,
    this.esCorrecta,
    this.respuestaCorrecta,
    this.mensaje,
    this.respuestas = 0,
    this.opciones = const [],
  });

  TcpePreguntaSemanaVigenteEntity copyWith({
    BigInt? codPreguntaSemana,
    String? titulo,
    String? pregunta,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? diasRestantes,
    bool? mostrarRespuesta,
    bool? respondida,
    BigInt? codRsptaOpElegida,
    bool? esCorrecta,
    String? respuestaCorrecta,
    String? mensaje,
    int? respuestas,
    List<TcpeOpcionSemanaEntity>? opciones,
  }) => TcpePreguntaSemanaVigenteEntity(
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    titulo: titulo ?? this.titulo,
    pregunta: pregunta ?? this.pregunta,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    diasRestantes: diasRestantes ?? this.diasRestantes,
    mostrarRespuesta: mostrarRespuesta ?? this.mostrarRespuesta,
    respondida: respondida ?? this.respondida,
    codRsptaOpElegida: codRsptaOpElegida ?? this.codRsptaOpElegida,
    esCorrecta: esCorrecta ?? this.esCorrecta,
    respuestaCorrecta: respuestaCorrecta ?? this.respuestaCorrecta,
    mensaje: mensaje ?? this.mensaje,
    respuestas: respuestas ?? this.respuestas,
    opciones: opciones ?? this.opciones,
  );
}
