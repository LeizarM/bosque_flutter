import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_examen_entity.dart';

/// `tcpe_examen`: Examen generado para un usuario dentro de un lote.
/// Columnas de `p_list_tcpe_Examen` (sin `password2`) más `nombreUsuario`.
class TcpeExamenModel {
  final BigInt codExamen;
  final BigInt? codRolExamen;
  final BigInt? codUsuario;
  final BigInt? codPostulacion;
  final bool? esPostulacion;
  final double? resultado;
  final String? observaciones;
  final String? titulo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final BigInt? preguntaActual;
  final DateTime? ultimaActividad;
  final int? salidasPestana;
  final DateTime? ultimaSalida;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeExamenModel({
    required this.codExamen,
    this.codRolExamen,
    this.codUsuario,
    this.codPostulacion,
    this.esPostulacion,
    this.resultado,
    this.observaciones,
    this.titulo,
    this.fechaInicio,
    this.fechaFin,
    this.preguntaActual,
    this.ultimaActividad,
    this.salidasPestana,
    this.ultimaSalida,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeExamenModel.fromJson(Map<String, dynamic> json) => TcpeExamenModel(
    codExamen: tcpeBigInt(json['codExamen']) ?? BigInt.zero,
    codRolExamen: tcpeBigInt(json['codRolExamen']),
    codUsuario: tcpeBigInt(json['codUsuario']),
    codPostulacion: tcpeBigInt(json['codPostulacion']),
    esPostulacion: tcpeBool(json['esPostulacion']),
    resultado: tcpeDouble(json['resultado']),
    observaciones: tcpeTexto(json['observaciones']),
    titulo: tcpeTexto(json['titulo']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    preguntaActual: tcpeBigInt(json['preguntaActual']),
    ultimaActividad: tcpeFecha(json['ultimaActividad']),
    salidasPestana: tcpeInt(json['salidasPestana']),
    ultimaSalida: tcpeFecha(json['ultimaSalida']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codExamen': codExamen.toInt(),
    'codRolExamen': codRolExamen?.toInt(),
    'codUsuario': codUsuario?.toInt(),
    'codPostulacion': codPostulacion?.toInt(),
    'esPostulacion': esPostulacion,
    'resultado': resultado,
    'observaciones': observaciones,
    'titulo': titulo,
    'fechaInicio': tcpeFechaHoraJson(fechaInicio),
    'fechaFin': tcpeFechaHoraJson(fechaFin),
    'preguntaActual': preguntaActual?.toInt(),
    'ultimaActividad': tcpeFechaHoraJson(ultimaActividad),
    'salidasPestana': salidasPestana,
    'ultimaSalida': tcpeFechaHoraJson(ultimaSalida),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeExamenEntity toEntity() => TcpeExamenEntity(
    codExamen: codExamen,
    codRolExamen: codRolExamen,
    codUsuario: codUsuario,
    codPostulacion: codPostulacion,
    esPostulacion: esPostulacion,
    resultado: resultado,
    observaciones: observaciones,
    titulo: titulo,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    preguntaActual: preguntaActual,
    ultimaActividad: ultimaActividad,
    salidasPestana: salidasPestana,
    ultimaSalida: ultimaSalida,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeExamenModel.fromEntity(TcpeExamenEntity e) => TcpeExamenModel(
    codExamen: e.codExamen,
    codRolExamen: e.codRolExamen,
    codUsuario: e.codUsuario,
    codPostulacion: e.codPostulacion,
    esPostulacion: e.esPostulacion,
    resultado: e.resultado,
    observaciones: e.observaciones,
    titulo: e.titulo,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    preguntaActual: e.preguntaActual,
    ultimaActividad: e.ultimaActividad,
    salidasPestana: e.salidasPestana,
    ultimaSalida: e.ultimaSalida,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
