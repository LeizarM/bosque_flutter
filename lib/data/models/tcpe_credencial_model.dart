import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';

/// Login y clave temporal en claro de un examen recién generado o regenerada.
/// La clave solo existe en esta respuesta: en la base queda el hash.
class TcpeCredencialModel {
  final BigInt? codExamen;
  final BigInt? codUsuario;
  final String? login;
  final String? password;
  final String? ci;
  final String? nombreCompleto;
  final BigInt? codEmpleado;

  const TcpeCredencialModel({
    this.codExamen,
    this.codUsuario,
    this.login,
    this.password,
    this.ci,
    this.nombreCompleto,
    this.codEmpleado,
  });

  factory TcpeCredencialModel.fromJson(Map<String, dynamic> json) => TcpeCredencialModel(
    codExamen: tcpeBigInt(json['codExamen']),
    codUsuario: tcpeBigInt(json['codUsuario']),
    login: tcpeTexto(json['login']),
    password: tcpeTexto(json['password']),
    ci: tcpeTexto(json['ci']),
    nombreCompleto: tcpeTexto(json['nombreCompleto']),
    codEmpleado: tcpeBigInt(json['codEmpleado']),
  );

  Map<String, dynamic> toJson() => {
    'codExamen': codExamen?.toInt(),
    'codUsuario': codUsuario?.toInt(),
    'login': login,
    'password': password,
    'ci': ci,
    'nombreCompleto': nombreCompleto,
    'codEmpleado': codEmpleado?.toInt(),
  };

  TcpeCredencialEntity toEntity() => TcpeCredencialEntity(
    codExamen: codExamen,
    codUsuario: codUsuario,
    login: login,
    password: password,
    ci: ci,
    nombreCompleto: nombreCompleto,
    codEmpleado: codEmpleado,
  );

  factory TcpeCredencialModel.fromEntity(TcpeCredencialEntity e) => TcpeCredencialModel(
    codExamen: e.codExamen,
    codUsuario: e.codUsuario,
    login: e.login,
    password: e.password,
    ci: e.ci,
    nombreCompleto: e.nombreCompleto,
    codEmpleado: e.codEmpleado,
  );
}
