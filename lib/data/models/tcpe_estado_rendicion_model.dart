import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';

/// Estado de un examen para quien lo rinde (`p_list_tcpe_Rendir` M y E).
class TcpeEstadoRendicionModel {
  final BigInt codExamen;
  final BigInt? codRolExamen;
  final String? titulo;
  final String? nombreClasificacion;
  final String? modalidad;
  final int duracionMinutos;
  final int totalPreguntas;
  final int respondidas;
  final String? estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? fechaLimite;
  final int segundosRestantes;
  final double? resultado;
  final double? notaAprobacion;
  final bool? aprobado;
  final bool? mostrarRespuestas;
  final String? mensajeEstado;
  final DateTime? inicioVentana;
  final DateTime? finVentana;

  const TcpeEstadoRendicionModel({
    required this.codExamen,
    this.codRolExamen,
    this.titulo,
    this.nombreClasificacion,
    this.modalidad,
    this.duracionMinutos = 0,
    this.totalPreguntas = 0,
    this.respondidas = 0,
    this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.fechaLimite,
    this.segundosRestantes = 0,
    this.resultado,
    this.notaAprobacion,
    this.aprobado,
    this.mostrarRespuestas,
    this.mensajeEstado,
    this.inicioVentana,
    this.finVentana,
  });

  factory TcpeEstadoRendicionModel.fromJson(Map<String, dynamic> json) => TcpeEstadoRendicionModel(
    codExamen: tcpeBigInt(json['codExamen']) ?? BigInt.zero,
    codRolExamen: tcpeBigInt(json['codRolExamen']),
    titulo: tcpeTexto(json['titulo']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    modalidad: tcpeTexto(json['modalidad']),
    duracionMinutos: tcpeInt(json['duracionMinutos']) ?? 0,
    totalPreguntas: tcpeInt(json['totalPreguntas']) ?? 0,
    respondidas: tcpeInt(json['respondidas']) ?? 0,
    estado: tcpeTexto(json['estado']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    fechaLimite: tcpeFecha(json['fechaLimite']),
    segundosRestantes: tcpeInt(json['segundosRestantes']) ?? 0,
    resultado: tcpeDouble(json['resultado']),
    notaAprobacion: tcpeDouble(json['notaAprobacion']),
    aprobado: tcpeBool(json['aprobado']),
    mostrarRespuestas: tcpeBool(json['mostrarRespuestas']),
    mensajeEstado: tcpeTexto(json['mensajeEstado']),
    inicioVentana: tcpeFecha(json['inicioVentana']),
    finVentana: tcpeFecha(json['finVentana']),
  );

  Map<String, dynamic> toJson() => {
    'codExamen': codExamen.toInt(),
    'codRolExamen': codRolExamen?.toInt(),
    'titulo': titulo,
    'nombreClasificacion': nombreClasificacion,
    'modalidad': modalidad,
    'duracionMinutos': duracionMinutos,
    'totalPreguntas': totalPreguntas,
    'respondidas': respondidas,
    'estado': estado,
    'fechaInicio': tcpeFechaHoraJson(fechaInicio),
    'fechaFin': tcpeFechaHoraJson(fechaFin),
    'fechaLimite': tcpeFechaHoraJson(fechaLimite),
    'segundosRestantes': segundosRestantes,
    'resultado': resultado,
    'notaAprobacion': notaAprobacion,
    'aprobado': aprobado,
    'mostrarRespuestas': mostrarRespuestas,
    'mensajeEstado': mensajeEstado,
    'inicioVentana': tcpeFechaHoraJson(inicioVentana),
    'finVentana': tcpeFechaHoraJson(finVentana),
  };

  TcpeEstadoRendicionEntity toEntity() => TcpeEstadoRendicionEntity(
    codExamen: codExamen,
    codRolExamen: codRolExamen,
    titulo: titulo,
    nombreClasificacion: nombreClasificacion,
    modalidad: modalidad,
    duracionMinutos: duracionMinutos,
    totalPreguntas: totalPreguntas,
    respondidas: respondidas,
    estado: estado,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    fechaLimite: fechaLimite,
    segundosRestantes: segundosRestantes,
    resultado: resultado,
    notaAprobacion: notaAprobacion,
    aprobado: aprobado,
    mostrarRespuestas: mostrarRespuestas,
    mensajeEstado: mensajeEstado,
    inicioVentana: inicioVentana,
    finVentana: finVentana,
  );

  factory TcpeEstadoRendicionModel.fromEntity(TcpeEstadoRendicionEntity e) => TcpeEstadoRendicionModel(
    codExamen: e.codExamen,
    codRolExamen: e.codRolExamen,
    titulo: e.titulo,
    nombreClasificacion: e.nombreClasificacion,
    modalidad: e.modalidad,
    duracionMinutos: e.duracionMinutos,
    totalPreguntas: e.totalPreguntas,
    respondidas: e.respondidas,
    estado: e.estado,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    fechaLimite: e.fechaLimite,
    segundosRestantes: e.segundosRestantes,
    resultado: e.resultado,
    notaAprobacion: e.notaAprobacion,
    aprobado: e.aprobado,
    mostrarRespuestas: e.mostrarRespuestas,
    mensajeEstado: e.mensajeEstado,
    inicioVentana: e.inicioVentana,
    finVentana: e.finVentana,
  );
}
