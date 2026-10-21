import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';

/// `tcpe_preguntaSemana` (v11). Lee las columnas de `p_list_tcpe_PreguntaSemana`
/// L; [toJson] manda solo las de la tabla (lo de la gestión es de solo lectura).
class TcpePreguntaSemanaModel {
  final BigInt codPreguntaSemana;
  final BigInt? codPregunta;
  final String? titulo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool mostrarRespuesta;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;
  final String? tituloMostrado;
  final String? pregunta;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  final String? estado;
  final int respuestas;
  final int correctas;
  final double? porcentajeAcierto;

  const TcpePreguntaSemanaModel({
    required this.codPreguntaSemana,
    this.codPregunta,
    this.titulo,
    this.fechaInicio,
    this.fechaFin,
    this.mostrarRespuesta = true,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
    this.tituloMostrado,
    this.pregunta,
    this.codClasificacion,
    this.nombreClasificacion,
    this.estado,
    this.respuestas = 0,
    this.correctas = 0,
    this.porcentajeAcierto,
  });

  factory TcpePreguntaSemanaModel.fromJson(Map<String, dynamic> json) => TcpePreguntaSemanaModel(
    codPreguntaSemana: tcpeBigInt(json['codPreguntaSemana']) ?? BigInt.zero,
    codPregunta: tcpeBigInt(json['codPregunta']),
    titulo: tcpeTexto(json['titulo']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    mostrarRespuesta: tcpeBool(json['mostrarRespuesta']) ?? true,
    activo: tcpeBool(json['activo']) ?? true,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
    tituloMostrado: tcpeTexto(json['tituloMostrado']),
    pregunta: tcpeTexto(json['pregunta']),
    codClasificacion: tcpeBigInt(json['codClasificacion']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    estado: tcpeTexto(json['estado']),
    respuestas: tcpeInt(json['respuestas']) ?? 0,
    correctas: tcpeInt(json['correctas']) ?? 0,
    porcentajeAcierto: tcpeDouble(json['porcentajeAcierto']),
  );

  /// Las columnas de la tabla, para el CRUD genérico.
  Map<String, dynamic> toJson() => {
    'codPreguntaSemana': codPreguntaSemana.toInt(),
    'codPregunta': codPregunta?.toInt(),
    'titulo': titulo,
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
    'mostrarRespuesta': mostrarRespuesta,
    'activo': activo,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  /// El cuerpo de `/examenes/pregunta-semana/guardar`: sin PK es un alta. Las
  /// reglas (pregunta elegible, fechas, título) las aplica el SP.
  Map<String, dynamic> toGuardarJson() => {
    if (codPreguntaSemana > BigInt.zero) 'codPreguntaSemana': codPreguntaSemana.toInt(),
    'codPregunta': codPregunta?.toInt(),
    'titulo': (titulo ?? '').trim().isEmpty ? null : titulo!.trim(),
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
    'mostrarRespuesta': mostrarRespuesta,
  };

  TcpePreguntaSemanaEntity toEntity() => TcpePreguntaSemanaEntity(
    codPreguntaSemana: codPreguntaSemana,
    codPregunta: codPregunta,
    titulo: titulo,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    mostrarRespuesta: mostrarRespuesta,
    activo: activo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
    tituloMostrado: tituloMostrado,
    pregunta: pregunta,
    codClasificacion: codClasificacion,
    nombreClasificacion: nombreClasificacion,
    estado: estado,
    respuestas: respuestas,
    correctas: correctas,
    porcentajeAcierto: porcentajeAcierto,
  );

  factory TcpePreguntaSemanaModel.fromEntity(TcpePreguntaSemanaEntity e) => TcpePreguntaSemanaModel(
    codPreguntaSemana: e.codPreguntaSemana,
    codPregunta: e.codPregunta,
    titulo: e.titulo,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    mostrarRespuesta: e.mostrarRespuesta,
    activo: e.activo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
    tituloMostrado: e.tituloMostrado,
    pregunta: e.pregunta,
    codClasificacion: e.codClasificacion,
    nombreClasificacion: e.nombreClasificacion,
    estado: e.estado,
    respuestas: e.respuestas,
    correctas: e.correctas,
    porcentajeAcierto: e.porcentajeAcierto,
  );
}
