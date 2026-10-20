import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_sesion_postulante_entity.dart';

/// Respuesta del login del postulante (`/examen-publico/auth/login`).
class TcpeSesionPostulanteModel {
  final String? token;
  final DateTime? expiracion;
  final BigInt? codUsuario;
  final String? login;
  final bool datosCompletos;
  final String? nombres;

  const TcpeSesionPostulanteModel({
    this.token,
    this.expiracion,
    this.codUsuario,
    this.login,
    this.datosCompletos = false,
    this.nombres,
  });

  factory TcpeSesionPostulanteModel.fromJson(Map<String, dynamic> json) => TcpeSesionPostulanteModel(
    token: tcpeTexto(json['token']),
    expiracion: tcpeFecha(json['expiracion']),
    codUsuario: tcpeBigInt(json['codUsuario']),
    login: tcpeTexto(json['login']),
    datosCompletos: tcpeBool(json['datosCompletos']) ?? false,
    nombres: tcpeTexto(json['nombres']),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'expiracion': tcpeFechaHoraJson(expiracion),
    'codUsuario': codUsuario?.toInt(),
    'login': login,
    'datosCompletos': datosCompletos,
    'nombres': nombres,
  };

  TcpeSesionPostulanteEntity toEntity() => TcpeSesionPostulanteEntity(
    token: token,
    expiracion: expiracion,
    codUsuario: codUsuario,
    login: login,
    datosCompletos: datosCompletos,
    nombres: nombres,
  );

  factory TcpeSesionPostulanteModel.fromEntity(TcpeSesionPostulanteEntity e) => TcpeSesionPostulanteModel(
    token: e.token,
    expiracion: e.expiracion,
    codUsuario: e.codUsuario,
    login: e.login,
    datosCompletos: e.datosCompletos,
    nombres: e.nombres,
  );
}
