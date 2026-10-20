import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respuesta_h_entity.dart';

/// `tcpe_respuestaH`: Foto de la respuesta en un examen, con lo que contestó el usuario.
/// Columnas de `p_list_tcpe_RespuestaH` (sin `password2`) más `nombreUsuario`.
class TcpeRespuestaHModel {
  final BigInt codRespuestaH;
  final BigInt? codPreguntaH;
  final BigInt? codPregunta;
  final BigInt? codRespuesta;
  final String? respuesta;
  final String? respuestaU;
  final bool esCerrada;
  final bool? esCorrecta;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeRespuestaHModel({
    required this.codRespuestaH,
    this.codPreguntaH,
    this.codPregunta,
    this.codRespuesta,
    this.respuesta,
    this.respuestaU,
    this.esCerrada = false,
    this.esCorrecta,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeRespuestaHModel.fromJson(Map<String, dynamic> json) => TcpeRespuestaHModel(
    codRespuestaH: tcpeBigInt(json['codRespuestaH']) ?? BigInt.zero,
    codPreguntaH: tcpeBigInt(json['codPreguntaH']),
    codPregunta: tcpeBigInt(json['codPregunta']),
    codRespuesta: tcpeBigInt(json['codRespuesta']),
    respuesta: tcpeTexto(json['respuesta']),
    respuestaU: tcpeTexto(json['respuestaU']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    esCorrecta: tcpeBool(json['esCorrecta']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRespuestaH': codRespuestaH.toInt(),
    'codPreguntaH': codPreguntaH?.toInt(),
    'codPregunta': codPregunta?.toInt(),
    'codRespuesta': codRespuesta?.toInt(),
    'respuesta': respuesta,
    'respuestaU': respuestaU,
    'esCerrada': esCerrada,
    'esCorrecta': esCorrecta,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeRespuestaHEntity toEntity() => TcpeRespuestaHEntity(
    codRespuestaH: codRespuestaH,
    codPreguntaH: codPreguntaH,
    codPregunta: codPregunta,
    codRespuesta: codRespuesta,
    respuesta: respuesta,
    respuestaU: respuestaU,
    esCerrada: esCerrada,
    esCorrecta: esCorrecta,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeRespuestaHModel.fromEntity(TcpeRespuestaHEntity e) => TcpeRespuestaHModel(
    codRespuestaH: e.codRespuestaH,
    codPreguntaH: e.codPreguntaH,
    codPregunta: e.codPregunta,
    codRespuesta: e.codRespuesta,
    respuesta: e.respuesta,
    respuestaU: e.respuestaU,
    esCerrada: e.esCerrada,
    esCorrecta: e.esCorrecta,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
