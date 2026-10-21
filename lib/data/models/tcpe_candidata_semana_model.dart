import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_candidata_semana_entity.dart';

/// Una pregunta del banco para elegir como pregunta de la semana
/// (`p_list_tcpe_PreguntaSemana` B).
class TcpeCandidataSemanaModel {
  final BigInt codPregunta;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  final String? nombreArea;
  final String? pregunta;
  final int cantOpciones;
  final int cantValidas;
  final bool puedeElegirse;
  final String? motivo;
  final int vecesUsada;

  const TcpeCandidataSemanaModel({
    required this.codPregunta,
    this.codClasificacion,
    this.nombreClasificacion,
    this.nombreArea,
    this.pregunta,
    this.cantOpciones = 0,
    this.cantValidas = 0,
    this.puedeElegirse = false,
    this.motivo,
    this.vecesUsada = 0,
  });

  factory TcpeCandidataSemanaModel.fromJson(Map<String, dynamic> json) => TcpeCandidataSemanaModel(
    codPregunta: tcpeBigInt(json['codPregunta']) ?? BigInt.zero,
    codClasificacion: tcpeBigInt(json['codClasificacion']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    nombreArea: tcpeTexto(json['nombreArea']),
    pregunta: tcpeTexto(json['pregunta']),
    cantOpciones: tcpeInt(json['cantOpciones']) ?? 0,
    cantValidas: tcpeInt(json['cantValidas']) ?? 0,
    puedeElegirse: tcpeBool(json['puedeElegirse']) ?? false,
    motivo: tcpeTexto(json['motivo']),
    vecesUsada: tcpeInt(json['vecesUsada']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'codPregunta': codPregunta.toInt(),
    'codClasificacion': codClasificacion?.toInt(),
    'nombreClasificacion': nombreClasificacion,
    'nombreArea': nombreArea,
    'pregunta': pregunta,
    'cantOpciones': cantOpciones,
    'cantValidas': cantValidas,
    'puedeElegirse': puedeElegirse,
    'motivo': motivo,
    'vecesUsada': vecesUsada,
  };

  TcpeCandidataSemanaEntity toEntity() => TcpeCandidataSemanaEntity(
    codPregunta: codPregunta,
    codClasificacion: codClasificacion,
    nombreClasificacion: nombreClasificacion,
    nombreArea: nombreArea,
    pregunta: pregunta,
    cantOpciones: cantOpciones,
    cantValidas: cantValidas,
    puedeElegirse: puedeElegirse,
    motivo: motivo,
    vecesUsada: vecesUsada,
  );

  factory TcpeCandidataSemanaModel.fromEntity(TcpeCandidataSemanaEntity e) => TcpeCandidataSemanaModel(
    codPregunta: e.codPregunta,
    codClasificacion: e.codClasificacion,
    nombreClasificacion: e.nombreClasificacion,
    nombreArea: e.nombreArea,
    pregunta: e.pregunta,
    cantOpciones: e.cantOpciones,
    cantValidas: e.cantValidas,
    puedeElegirse: e.puedeElegirse,
    motivo: e.motivo,
    vecesUsada: e.vecesUsada,
  );
}
