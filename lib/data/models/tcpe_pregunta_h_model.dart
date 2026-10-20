import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_h_entity.dart';

/// `tcpe_preguntaH`: Foto de una pregunta tal como quedó en un examen generado.
/// Columnas de `p_list_tcpe_PreguntaH` (sin `password2`) más `nombreUsuario`.
class TcpePreguntaHModel {
  final BigInt codPreguntaH;
  final BigInt? codPregunta;
  final BigInt? codClasificacion;
  final BigInt? codExamen;
  final String? pregunta;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpePreguntaHModel({
    required this.codPreguntaH,
    this.codPregunta,
    this.codClasificacion,
    this.codExamen,
    this.pregunta,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpePreguntaHModel.fromJson(Map<String, dynamic> json) => TcpePreguntaHModel(
    codPreguntaH: tcpeBigInt(json['codPreguntaH']) ?? BigInt.zero,
    codPregunta: tcpeBigInt(json['codPregunta']),
    codClasificacion: tcpeBigInt(json['codClasificacion']),
    codExamen: tcpeBigInt(json['codExamen']),
    pregunta: tcpeTexto(json['pregunta']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codPreguntaH': codPreguntaH.toInt(),
    'codPregunta': codPregunta?.toInt(),
    'codClasificacion': codClasificacion?.toInt(),
    'codExamen': codExamen?.toInt(),
    'pregunta': pregunta,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpePreguntaHEntity toEntity() => TcpePreguntaHEntity(
    codPreguntaH: codPreguntaH,
    codPregunta: codPregunta,
    codClasificacion: codClasificacion,
    codExamen: codExamen,
    pregunta: pregunta,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpePreguntaHModel.fromEntity(TcpePreguntaHEntity e) => TcpePreguntaHModel(
    codPreguntaH: e.codPreguntaH,
    codPregunta: e.codPregunta,
    codClasificacion: e.codClasificacion,
    codExamen: e.codExamen,
    pregunta: e.pregunta,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
