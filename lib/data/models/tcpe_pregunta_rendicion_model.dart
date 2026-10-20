import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_rendicion_entity.dart';

/// Pregunta de un examen en curso (`p_list_tcpe_Rendir` P).
class TcpePreguntaRendicionModel {
  final BigInt codPreguntaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;
  final BigInt? codRespuestaH;
  final String? respuestaU;
  final bool respondida;

  const TcpePreguntaRendicionModel({
    required this.codPreguntaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.codRespuestaH,
    this.respuestaU,
    this.respondida = false,
  });

  factory TcpePreguntaRendicionModel.fromJson(Map<String, dynamic> json) => TcpePreguntaRendicionModel(
    codPreguntaH: tcpeBigInt(json['codPreguntaH']) ?? BigInt.zero,
    orden: tcpeInt(json['orden']) ?? 0,
    pregunta: tcpeTexto(json['pregunta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    codRespuestaH: tcpeBigInt(json['codRespuestaH']),
    respuestaU: tcpeTexto(json['respuestaU']),
    respondida: tcpeBool(json['respondida']) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'codPreguntaH': codPreguntaH.toInt(),
    'orden': orden,
    'pregunta': pregunta,
    'esCerrada': esCerrada,
    'codRespuestaH': codRespuestaH?.toInt(),
    'respuestaU': respuestaU,
    'respondida': respondida,
  };

  TcpePreguntaRendicionEntity toEntity() => TcpePreguntaRendicionEntity(
    codPreguntaH: codPreguntaH,
    orden: orden,
    pregunta: pregunta,
    esCerrada: esCerrada,
    codRespuestaH: codRespuestaH,
    respuestaU: respuestaU,
    respondida: respondida,
  );

  factory TcpePreguntaRendicionModel.fromEntity(TcpePreguntaRendicionEntity e) => TcpePreguntaRendicionModel(
    codPreguntaH: e.codPreguntaH,
    orden: e.orden,
    pregunta: e.pregunta,
    esCerrada: e.esCerrada,
    codRespuestaH: e.codRespuestaH,
    respuestaU: e.respuestaU,
    respondida: e.respondida,
  );
}
