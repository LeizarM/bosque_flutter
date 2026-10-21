import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';

/// `tcpe_preguntaSemana` (v12). Lee las columnas de `p_list_tcpe_PreguntaSemana`
/// L; [toJson] manda solo las de la tabla (lo de la gestión es de solo lectura).
class TcpePreguntaSemanaModel {
  final BigInt codPreguntaSemana;
  final String? titulo;
  final String? pregunta;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;
  final String? tituloMostrado;
  final String? estado;
  final int respuestas;

  const TcpePreguntaSemanaModel({
    required this.codPreguntaSemana,
    this.titulo,
    this.pregunta,
    this.fechaInicio,
    this.fechaFin,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
    this.tituloMostrado,
    this.estado,
    this.respuestas = 0,
  });

  factory TcpePreguntaSemanaModel.fromJson(Map<String, dynamic> json) => TcpePreguntaSemanaModel(
    codPreguntaSemana: tcpeBigInt(json['codPreguntaSemana']) ?? BigInt.zero,
    titulo: tcpeTexto(json['titulo']),
    pregunta: tcpeTexto(json['pregunta']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    activo: tcpeBool(json['activo']) ?? true,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
    tituloMostrado: tcpeTexto(json['tituloMostrado']),
    estado: tcpeTexto(json['estado']),
    respuestas: tcpeInt(json['respuestas']) ?? 0,
  );

  /// Las columnas de la tabla, para el CRUD genérico.
  Map<String, dynamic> toJson() => {
    'codPreguntaSemana': codPreguntaSemana.toInt(),
    'titulo': titulo,
    'pregunta': pregunta,
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
    'activo': activo,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  /// El cuerpo de `/examenes/pregunta-semana/guardar`: sin PK es un alta. Las
  /// reglas (texto, fechas, título) las aplica el SP.
  Map<String, dynamic> toGuardarJson() => {
    if (codPreguntaSemana > BigInt.zero) 'codPreguntaSemana': codPreguntaSemana.toInt(),
    'titulo': (titulo ?? '').trim().isEmpty ? null : titulo!.trim(),
    'pregunta': (pregunta ?? '').trim().isEmpty ? null : pregunta!.trim(),
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
  };

  TcpePreguntaSemanaEntity toEntity() => TcpePreguntaSemanaEntity(
    codPreguntaSemana: codPreguntaSemana,
    titulo: titulo,
    pregunta: pregunta,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    activo: activo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
    tituloMostrado: tituloMostrado,
    estado: estado,
    respuestas: respuestas,
  );

  factory TcpePreguntaSemanaModel.fromEntity(TcpePreguntaSemanaEntity e) => TcpePreguntaSemanaModel(
    codPreguntaSemana: e.codPreguntaSemana,
    titulo: e.titulo,
    pregunta: e.pregunta,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    activo: e.activo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
    tituloMostrado: e.tituloMostrado,
    estado: e.estado,
    respuestas: e.respuestas,
  );
}
