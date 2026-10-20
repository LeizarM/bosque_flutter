import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respuesta_entity.dart';

/// `tcpe_respuesta`: Respuesta de una pregunta del banco: modelo (abierta) o cabecera de opciones (cerrada).
/// Columnas de `p_list_tcpe_Respuesta` (sin `password2`) más `nombreUsuario`.
class TcpeRespuestaModel {
  final BigInt codRespuesta;
  final BigInt? codPregunta;
  final int? prioridad;
  final String? respuesta;
  final bool esCerrada;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeRespuestaModel({
    required this.codRespuesta,
    this.codPregunta,
    this.prioridad,
    this.respuesta,
    this.esCerrada = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeRespuestaModel.fromJson(Map<String, dynamic> json) => TcpeRespuestaModel(
    codRespuesta: tcpeBigInt(json['codRespuesta']) ?? BigInt.zero,
    codPregunta: tcpeBigInt(json['codPregunta']),
    prioridad: tcpeInt(json['prioridad']),
    respuesta: tcpeTexto(json['respuesta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRespuesta': codRespuesta.toInt(),
    'codPregunta': codPregunta?.toInt(),
    'prioridad': prioridad,
    'respuesta': respuesta,
    'esCerrada': esCerrada,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeRespuestaEntity toEntity() => TcpeRespuestaEntity(
    codRespuesta: codRespuesta,
    codPregunta: codPregunta,
    prioridad: prioridad,
    respuesta: respuesta,
    esCerrada: esCerrada,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeRespuestaModel.fromEntity(TcpeRespuestaEntity e) => TcpeRespuestaModel(
    codRespuesta: e.codRespuesta,
    codPregunta: e.codPregunta,
    prioridad: e.prioridad,
    respuesta: e.respuesta,
    esCerrada: e.esCerrada,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
