import 'package:bosque_flutter/domain/entities/sesion_entity.dart';

/// Fila de trec_sesion tal como la mandan `POST /sesiones/abiertas` y `/sesiones/historial`.
/// Las fechas llegan como "yyyy-MM-dd HH:mm:ss" en la hora del servidor (La Paz).
class SesionModel {
  final BigInt idSesion;
  final int codUsuario;
  final String plataforma;
  final String? versionApp;
  final String? ip;
  final DateTime? fechaInicio;
  final DateTime? fechaVence;
  final DateTime? fechaUltimaSenal;
  final DateTime? fechaCierre;
  final String? motivoCierre;
  final int? codUsuarioCierre;
  final int? audUsuario;
  final DateTime? audFecha;
  final String login;
  final String nombreCompleto;
  final String? loginCierre;
  final String estado;
  final bool esActual;

  const SesionModel({
    required this.idSesion,
    required this.codUsuario,
    required this.plataforma,
    required this.versionApp,
    required this.ip,
    required this.fechaInicio,
    required this.fechaVence,
    required this.fechaUltimaSenal,
    required this.fechaCierre,
    required this.motivoCierre,
    required this.codUsuarioCierre,
    required this.audUsuario,
    required this.audFecha,
    required this.login,
    required this.nombreCompleto,
    required this.loginCierre,
    required this.estado,
    required this.esActual,
  });

  static DateTime? _fecha(Object? valor) => valor == null ? null : DateTime.tryParse(valor.toString());

  factory SesionModel.fromJson(Map<String, dynamic> json) {
    return SesionModel(
      idSesion: BigInt.from((json['idSesion'] as num?)?.toInt() ?? 0),
      codUsuario: (json['codUsuario'] as num?)?.toInt() ?? 0,
      plataforma: json['plataforma'] as String? ?? 'desconocida',
      versionApp: json['versionApp'] as String?,
      ip: json['ip'] as String?,
      fechaInicio: _fecha(json['fechaInicio']),
      fechaVence: _fecha(json['fechaVence']),
      fechaUltimaSenal: _fecha(json['fechaUltimaSenal']),
      fechaCierre: _fecha(json['fechaCierre']),
      motivoCierre: json['motivoCierre'] as String?,
      codUsuarioCierre: (json['codUsuarioCierre'] as num?)?.toInt(),
      audUsuario: (json['audUsuario'] as num?)?.toInt(),
      audFecha: _fecha(json['audFecha']),
      login: json['login'] as String? ?? '',
      nombreCompleto: (json['nombreCompleto'] as String? ?? '').trim(),
      loginCierre: json['loginCierre'] as String?,
      estado: json['estado'] as String? ?? 'X',
      esActual: json['esActual'] as bool? ?? false,
    );
  }

  SesionEntity toEntity() => SesionEntity(
    idSesion: idSesion,
    codUsuario: codUsuario,
    plataforma: plataforma,
    versionApp: versionApp,
    ip: ip,
    fechaInicio: fechaInicio,
    fechaVence: fechaVence,
    fechaUltimaSenal: fechaUltimaSenal,
    fechaCierre: fechaCierre,
    motivoCierre: motivoCierre,
    codUsuarioCierre: codUsuarioCierre,
    audUsuario: audUsuario,
    audFecha: audFecha,
    login: login,
    nombreCompleto: nombreCompleto,
    loginCierre: loginCierre,
    estado: estado,
    esActual: esActual,
  );
}
