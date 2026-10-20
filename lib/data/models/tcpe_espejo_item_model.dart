import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_espejo_item_entity.dart';

/// Una fila del espejo de un examen en curso (`p_list_tcpe_Monitor` E): la pregunta actual, una fila por opción.
class TcpeEspejoItemModel {
  final BigInt codExamen;
  final String? nombreCompleto;
  final String? estado;
  final int segundosRestantes;
  final String? conexion;
  final int totalPreguntas;
  final int respondidas;
  final int? ordenActual;
  final BigInt? codPreguntaH;
  final String? pregunta;
  final bool esCerrada;
  final String? respuestaU;
  final BigInt? codRsptaOpH;
  final String? opcionRspta;
  final bool marcada;
  final bool? esValido;

  const TcpeEspejoItemModel({
    required this.codExamen,
    this.nombreCompleto,
    this.estado,
    this.segundosRestantes = 0,
    this.conexion,
    this.totalPreguntas = 0,
    this.respondidas = 0,
    this.ordenActual,
    this.codPreguntaH,
    this.pregunta,
    this.esCerrada = false,
    this.respuestaU,
    this.codRsptaOpH,
    this.opcionRspta,
    this.marcada = false,
    this.esValido,
  });

  factory TcpeEspejoItemModel.fromJson(Map<String, dynamic> json) => TcpeEspejoItemModel(
    codExamen: tcpeBigInt(json['codExamen']) ?? BigInt.zero,
    nombreCompleto: tcpeTexto(json['nombreCompleto']),
    estado: tcpeTexto(json['estado']),
    segundosRestantes: tcpeInt(json['segundosRestantes']) ?? 0,
    conexion: tcpeTexto(json['conexion']),
    totalPreguntas: tcpeInt(json['totalPreguntas']) ?? 0,
    respondidas: tcpeInt(json['respondidas']) ?? 0,
    ordenActual: tcpeInt(json['ordenActual']),
    codPreguntaH: tcpeBigInt(json['codPreguntaH']),
    pregunta: tcpeTexto(json['pregunta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    respuestaU: tcpeTexto(json['respuestaU']),
    codRsptaOpH: tcpeBigInt(json['codRsptaOpH']),
    opcionRspta: tcpeTexto(json['opcionRspta']),
    marcada: tcpeBool(json['marcada']) ?? false,
    esValido: tcpeBool(json['esValido']),
  );

  Map<String, dynamic> toJson() => {
    'codExamen': codExamen.toInt(),
    'nombreCompleto': nombreCompleto,
    'estado': estado,
    'segundosRestantes': segundosRestantes,
    'conexion': conexion,
    'totalPreguntas': totalPreguntas,
    'respondidas': respondidas,
    'ordenActual': ordenActual,
    'codPreguntaH': codPreguntaH?.toInt(),
    'pregunta': pregunta,
    'esCerrada': esCerrada,
    'respuestaU': respuestaU,
    'codRsptaOpH': codRsptaOpH?.toInt(),
    'opcionRspta': opcionRspta,
    'marcada': marcada,
    'esValido': esValido,
  };

  TcpeEspejoItemEntity toEntity() => TcpeEspejoItemEntity(
    codExamen: codExamen,
    nombreCompleto: nombreCompleto,
    estado: estado,
    segundosRestantes: segundosRestantes,
    conexion: conexion,
    totalPreguntas: totalPreguntas,
    respondidas: respondidas,
    ordenActual: ordenActual,
    codPreguntaH: codPreguntaH,
    pregunta: pregunta,
    esCerrada: esCerrada,
    respuestaU: respuestaU,
    codRsptaOpH: codRsptaOpH,
    opcionRspta: opcionRspta,
    marcada: marcada,
    esValido: esValido,
  );

  factory TcpeEspejoItemModel.fromEntity(TcpeEspejoItemEntity e) => TcpeEspejoItemModel(
    codExamen: e.codExamen,
    nombreCompleto: e.nombreCompleto,
    estado: e.estado,
    segundosRestantes: e.segundosRestantes,
    conexion: e.conexion,
    totalPreguntas: e.totalPreguntas,
    respondidas: e.respondidas,
    ordenActual: e.ordenActual,
    codPreguntaH: e.codPreguntaH,
    pregunta: e.pregunta,
    esCerrada: e.esCerrada,
    respuestaU: e.respuestaU,
    codRsptaOpH: e.codRsptaOpH,
    opcionRspta: e.opcionRspta,
    marcada: e.marcada,
    esValido: e.esValido,
  );
}
