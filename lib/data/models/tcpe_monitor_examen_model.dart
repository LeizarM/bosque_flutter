import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_examen_entity.dart';

/// Un examen del lote en el panel "En vivo" (`p_list_tcpe_Monitor` L).
class TcpeMonitorExamenModel {
  final BigInt codExamen;
  final String? login;
  final String? nombreCompleto;
  final String? ci;
  final String? estado;
  final DateTime? fechaInicio;
  final DateTime? fechaLimite;
  final int segundosRestantes;
  final int totalPreguntas;
  final int respondidas;
  final int? ordenActual;
  final DateTime? ultimaActividad;
  final int? segundosSinActividad;
  final String? conexion;
  final int salidasPestana;
  final DateTime? ultimaSalida;
  final double? resultado;

  const TcpeMonitorExamenModel({
    required this.codExamen,
    this.login,
    this.nombreCompleto,
    this.ci,
    this.estado,
    this.fechaInicio,
    this.fechaLimite,
    this.segundosRestantes = 0,
    this.totalPreguntas = 0,
    this.respondidas = 0,
    this.ordenActual,
    this.ultimaActividad,
    this.segundosSinActividad,
    this.conexion,
    this.salidasPestana = 0,
    this.ultimaSalida,
    this.resultado,
  });

  factory TcpeMonitorExamenModel.fromJson(Map<String, dynamic> json) => TcpeMonitorExamenModel(
    codExamen: tcpeBigInt(json['codExamen']) ?? BigInt.zero,
    login: tcpeTexto(json['login']),
    nombreCompleto: tcpeTexto(json['nombreCompleto']),
    ci: tcpeTexto(json['ci']),
    estado: tcpeTexto(json['estado']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaLimite: tcpeFecha(json['fechaLimite']),
    segundosRestantes: tcpeInt(json['segundosRestantes']) ?? 0,
    totalPreguntas: tcpeInt(json['totalPreguntas']) ?? 0,
    respondidas: tcpeInt(json['respondidas']) ?? 0,
    ordenActual: tcpeInt(json['ordenActual']),
    ultimaActividad: tcpeFecha(json['ultimaActividad']),
    segundosSinActividad: tcpeInt(json['segundosSinActividad']),
    conexion: tcpeTexto(json['conexion']),
    salidasPestana: tcpeInt(json['salidasPestana']) ?? 0,
    ultimaSalida: tcpeFecha(json['ultimaSalida']),
    resultado: tcpeDouble(json['resultado']),
  );

  Map<String, dynamic> toJson() => {
    'codExamen': codExamen.toInt(),
    'login': login,
    'nombreCompleto': nombreCompleto,
    'ci': ci,
    'estado': estado,
    'fechaInicio': tcpeFechaHoraJson(fechaInicio),
    'fechaLimite': tcpeFechaHoraJson(fechaLimite),
    'segundosRestantes': segundosRestantes,
    'totalPreguntas': totalPreguntas,
    'respondidas': respondidas,
    'ordenActual': ordenActual,
    'ultimaActividad': tcpeFechaHoraJson(ultimaActividad),
    'segundosSinActividad': segundosSinActividad,
    'conexion': conexion,
    'salidasPestana': salidasPestana,
    'ultimaSalida': tcpeFechaHoraJson(ultimaSalida),
    'resultado': resultado,
  };

  TcpeMonitorExamenEntity toEntity() => TcpeMonitorExamenEntity(
    codExamen: codExamen,
    login: login,
    nombreCompleto: nombreCompleto,
    ci: ci,
    estado: estado,
    fechaInicio: fechaInicio,
    fechaLimite: fechaLimite,
    segundosRestantes: segundosRestantes,
    totalPreguntas: totalPreguntas,
    respondidas: respondidas,
    ordenActual: ordenActual,
    ultimaActividad: ultimaActividad,
    segundosSinActividad: segundosSinActividad,
    conexion: conexion,
    salidasPestana: salidasPestana,
    ultimaSalida: ultimaSalida,
    resultado: resultado,
  );

  factory TcpeMonitorExamenModel.fromEntity(TcpeMonitorExamenEntity e) => TcpeMonitorExamenModel(
    codExamen: e.codExamen,
    login: e.login,
    nombreCompleto: e.nombreCompleto,
    ci: e.ci,
    estado: e.estado,
    fechaInicio: e.fechaInicio,
    fechaLimite: e.fechaLimite,
    segundosRestantes: e.segundosRestantes,
    totalPreguntas: e.totalPreguntas,
    respondidas: e.respondidas,
    ordenActual: e.ordenActual,
    ultimaActividad: e.ultimaActividad,
    segundosSinActividad: e.segundosSinActividad,
    conexion: e.conexion,
    salidasPestana: e.salidasPestana,
    ultimaSalida: e.ultimaSalida,
    resultado: e.resultado,
  );
}
