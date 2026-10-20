import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_entity.dart';

/// `tcpe_pregunta`: Pregunta del banco.
/// Columnas de `p_list_tcpe_Pregunta` (sin `password2`) más `nombreUsuario`.
class TcpePreguntaModel {
  final BigInt codPregunta;
  final BigInt? codClasificacion;
  final int? prioridad;
  final String? pregunta;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpePreguntaModel({
    required this.codPregunta,
    this.codClasificacion,
    this.prioridad,
    this.pregunta,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpePreguntaModel.fromJson(Map<String, dynamic> json) => TcpePreguntaModel(
    codPregunta: tcpeBigInt(json['codPregunta']) ?? BigInt.zero,
    codClasificacion: tcpeBigInt(json['codClasificacion']),
    prioridad: tcpeInt(json['prioridad']),
    pregunta: tcpeTexto(json['pregunta']),
    activo: tcpeBool(json['activo']) ?? true,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codPregunta': codPregunta.toInt(),
    'codClasificacion': codClasificacion?.toInt(),
    'prioridad': prioridad,
    'pregunta': pregunta,
    'activo': activo,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpePreguntaEntity toEntity() => TcpePreguntaEntity(
    codPregunta: codPregunta,
    codClasificacion: codClasificacion,
    prioridad: prioridad,
    pregunta: pregunta,
    activo: activo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpePreguntaModel.fromEntity(TcpePreguntaEntity e) => TcpePreguntaModel(
    codPregunta: e.codPregunta,
    codClasificacion: e.codClasificacion,
    prioridad: e.prioridad,
    pregunta: e.pregunta,
    activo: e.activo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
