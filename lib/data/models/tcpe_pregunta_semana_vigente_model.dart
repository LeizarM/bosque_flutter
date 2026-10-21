import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_vigente_entity.dart';

/// Una pregunta de la semana vigente (`/examenes/pregunta-semana/vigentes`:
/// `p_list_tcpe_PreguntaSemana` V). Es de solo lectura.
class TcpePreguntaSemanaVigenteModel {
  final BigInt codPreguntaSemana;
  final String? titulo;
  final String? pregunta;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasRestantes;
  final bool respondida;
  final String? respuesta;
  final DateTime? fechaRespuesta;
  final String? mensaje;
  final String? ayuda;
  final int maxRespuesta;

  const TcpePreguntaSemanaVigenteModel({
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

  factory TcpePreguntaSemanaVigenteModel.fromJson(Map<String, dynamic> json) {
    final max = tcpeInt(json['maxRespuesta']);
    return TcpePreguntaSemanaVigenteModel(
      codPreguntaSemana: tcpeBigInt(json['codPreguntaSemana']) ?? BigInt.zero,
      titulo: tcpeTexto(json['titulo']),
      pregunta: tcpeTexto(json['pregunta']),
      fechaInicio: tcpeFecha(json['fechaInicio']),
      fechaFin: tcpeFecha(json['fechaFin']),
      diasRestantes: tcpeInt(json['diasRestantes']),
      respondida: tcpeBool(json['respondida']) ?? false,
      respuesta: tcpeTexto(json['respuesta']),
      fechaRespuesta: tcpeFecha(json['fechaRespuesta']),
      mensaje: tcpeTexto(json['mensaje']),
      ayuda: tcpeTexto(json['ayuda']),
      // Un largo inválido no deja el campo sin tope: el de la columna lo vuelve a revisar el SP.
      maxRespuesta: max == null || max < 1 ? 500 : max,
    );
  }

  Map<String, dynamic> toJson() => {
    'codPreguntaSemana': codPreguntaSemana.toInt(),
    'titulo': titulo,
    'pregunta': pregunta,
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
    'diasRestantes': diasRestantes,
    'respondida': respondida,
    'respuesta': respuesta,
    'fechaRespuesta': tcpeFechaHoraJson(fechaRespuesta),
    'mensaje': mensaje,
    'ayuda': ayuda,
    'maxRespuesta': maxRespuesta,
  };

  TcpePreguntaSemanaVigenteEntity toEntity() => TcpePreguntaSemanaVigenteEntity(
    codPreguntaSemana: codPreguntaSemana,
    titulo: titulo,
    pregunta: pregunta,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    diasRestantes: diasRestantes,
    respondida: respondida,
    respuesta: respuesta,
    fechaRespuesta: fechaRespuesta,
    mensaje: mensaje,
    ayuda: ayuda,
    maxRespuesta: maxRespuesta,
  );

  factory TcpePreguntaSemanaVigenteModel.fromEntity(TcpePreguntaSemanaVigenteEntity e) =>
      TcpePreguntaSemanaVigenteModel(
        codPreguntaSemana: e.codPreguntaSemana,
        titulo: e.titulo,
        pregunta: e.pregunta,
        fechaInicio: e.fechaInicio,
        fechaFin: e.fechaFin,
        diasRestantes: e.diasRestantes,
        respondida: e.respondida,
        respuesta: e.respuesta,
        fechaRespuesta: e.fechaRespuesta,
        mensaje: e.mensaje,
        ayuda: e.ayuda,
        maxRespuesta: e.maxRespuesta,
      );
}
