import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_respondio_semana_entity.dart';

/// Quién respondió una pregunta de la semana (`p_list_tcpe_PreguntaSemana` R).
class TcpeRespondioSemanaModel {
  final BigInt codRsptaSemana;
  final BigInt? codUsuario;
  final String? login;
  final String? nombreCompleto;
  final String? cargo;
  final String? respuesta;
  final DateTime? fechaRespuesta;

  const TcpeRespondioSemanaModel({
    required this.codRsptaSemana,
    this.codUsuario,
    this.login,
    this.nombreCompleto,
    this.cargo,
    this.respuesta,
    this.fechaRespuesta,
  });

  factory TcpeRespondioSemanaModel.fromJson(Map<String, dynamic> json) => TcpeRespondioSemanaModel(
    codRsptaSemana: tcpeBigInt(json['codRsptaSemana']) ?? BigInt.zero,
    codUsuario: tcpeBigInt(json['codUsuario']),
    login: tcpeTexto(json['login']),
    nombreCompleto: tcpeTexto(json['nombreCompleto']),
    cargo: tcpeTexto(json['cargo']),
    respuesta: tcpeTexto(json['respuesta']),
    fechaRespuesta: tcpeFecha(json['fechaRespuesta']),
  );

  Map<String, dynamic> toJson() => {
    'codRsptaSemana': codRsptaSemana.toInt(),
    'codUsuario': codUsuario?.toInt(),
    'login': login,
    'nombreCompleto': nombreCompleto,
    'cargo': cargo,
    'respuesta': respuesta,
    'fechaRespuesta': tcpeFechaHoraJson(fechaRespuesta),
  };

  TcpeRespondioSemanaEntity toEntity() => TcpeRespondioSemanaEntity(
    codRsptaSemana: codRsptaSemana,
    codUsuario: codUsuario,
    login: login,
    nombreCompleto: nombreCompleto,
    cargo: cargo,
    respuesta: respuesta,
    fechaRespuesta: fechaRespuesta,
  );

  factory TcpeRespondioSemanaModel.fromEntity(TcpeRespondioSemanaEntity e) => TcpeRespondioSemanaModel(
    codRsptaSemana: e.codRsptaSemana,
    codUsuario: e.codUsuario,
    login: e.login,
    nombreCompleto: e.nombreCompleto,
    cargo: e.cargo,
    respuesta: e.respuesta,
    fechaRespuesta: e.fechaRespuesta,
  );
}
