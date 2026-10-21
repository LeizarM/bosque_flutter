import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/data/models/tcpe_opcion_semana_model.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_vigente_entity.dart';

/// Una pregunta de la semana vigente con sus opciones, como la arma
/// `/examenes/pregunta-semana/vigentes` (`V` + `O` de `p_list_tcpe_PreguntaSemana`).
class TcpePreguntaSemanaVigenteModel {
  final BigInt codPreguntaSemana;
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
  final String? mensaje;
  final int respuestas;
  final List<TcpeOpcionSemanaModel> opciones;

  const TcpePreguntaSemanaVigenteModel({
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

  factory TcpePreguntaSemanaVigenteModel.fromJson(Map<String, dynamic> json) {
    final crudas = json['opciones'];
    return TcpePreguntaSemanaVigenteModel(
      codPreguntaSemana: tcpeBigInt(json['codPreguntaSemana']) ?? BigInt.zero,
      titulo: tcpeTexto(json['titulo']),
      pregunta: tcpeTexto(json['pregunta']),
      fechaInicio: tcpeFecha(json['fechaInicio']),
      fechaFin: tcpeFecha(json['fechaFin']),
      diasRestantes: tcpeInt(json['diasRestantes']),
      mostrarRespuesta: tcpeBool(json['mostrarRespuesta']) ?? true,
      respondida: tcpeBool(json['respondida']) ?? false,
      codRsptaOpElegida: tcpeBigInt(json['codRsptaOpElegida']),
      esCorrecta: tcpeBool(json['esCorrecta']),
      respuestaCorrecta: tcpeTexto(json['respuestaCorrecta']),
      mensaje: tcpeTexto(json['mensaje']),
      respuestas: tcpeInt(json['respuestas']) ?? 0,
      opciones: [
        if (crudas is List)
          for (final o in crudas)
            if (o is Map) TcpeOpcionSemanaModel.fromJson(Map<String, dynamic>.from(o)),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'codPreguntaSemana': codPreguntaSemana.toInt(),
    'titulo': titulo,
    'pregunta': pregunta,
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
    'diasRestantes': diasRestantes,
    'mostrarRespuesta': mostrarRespuesta,
    'respondida': respondida,
    'codRsptaOpElegida': codRsptaOpElegida?.toInt(),
    'esCorrecta': esCorrecta,
    'respuestaCorrecta': respuestaCorrecta,
    'mensaje': mensaje,
    'respuestas': respuestas,
    'opciones': [for (final o in opciones) o.toJson()],
  };

  TcpePreguntaSemanaVigenteEntity toEntity() => TcpePreguntaSemanaVigenteEntity(
    codPreguntaSemana: codPreguntaSemana,
    titulo: titulo,
    pregunta: pregunta,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    diasRestantes: diasRestantes,
    mostrarRespuesta: mostrarRespuesta,
    respondida: respondida,
    codRsptaOpElegida: codRsptaOpElegida,
    esCorrecta: esCorrecta,
    respuestaCorrecta: respuestaCorrecta,
    mensaje: mensaje,
    respuestas: respuestas,
    opciones: [for (final o in opciones) o.toEntity()],
  );

  factory TcpePreguntaSemanaVigenteModel.fromEntity(TcpePreguntaSemanaVigenteEntity e) =>
      TcpePreguntaSemanaVigenteModel(
        codPreguntaSemana: e.codPreguntaSemana,
        titulo: e.titulo,
        pregunta: e.pregunta,
        fechaInicio: e.fechaInicio,
        fechaFin: e.fechaFin,
        diasRestantes: e.diasRestantes,
        mostrarRespuesta: e.mostrarRespuesta,
        respondida: e.respondida,
        codRsptaOpElegida: e.codRsptaOpElegida,
        esCorrecta: e.esCorrecta,
        respuestaCorrecta: e.respuestaCorrecta,
        mensaje: e.mensaje,
        respuestas: e.respuestas,
        opciones: [for (final o in e.opciones) TcpeOpcionSemanaModel.fromEntity(o)],
      );
}
