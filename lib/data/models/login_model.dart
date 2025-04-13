

import 'package:bosque_flutter/domain/entities/login_entity.dart';

class LoginModel {
  final String mensaje;
  final String status;
  final LoginDataModel? data;

  LoginModel({
    required this.mensaje,
    required this.status,
    this.data,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      mensaje: json['mensaje'] ?? 'Error desconocido',
      status: json['status'] ?? 'error',
      data: json['data'] != null ? LoginDataModel.fromJson(json['data']) : null,
    );
  }

  LoginEntity? toEntity() {
    if (data != null) {
      return LoginEntity(
        token: data!.token,
        bearer: data!.bearer,
        nombreCompleto: data!.nombreCompleto,
        cargo: data!.cargo,
        tipoUsuario: data!.tipoUsuario,
        codUsuario: data!.codUsuario,
        codEmpleado: data!.codEmpleado,
        codEmpresa: data!.codEmpresa,
        codCiudad: data!.codCiudad,
        login: data!.login,
        versionApp: data!.versionApp,
        codSucursal: data!.codSucursal,
      );
    }
    return null;
  }
}

class LoginDataModel {
  final String token;
  final String bearer;
  final String nombreCompleto;
  final String cargo;
  final String tipoUsuario;
  final int codUsuario;
  final int codEmpleado;
  final int codEmpresa;
  final int codCiudad;
  final String login;
  final String versionApp;
  final int codSucursal;

  LoginDataModel({
    required this.token,
    required this.bearer,
    required this.nombreCompleto,
    required this.cargo,
    required this.tipoUsuario,
    required this.codUsuario,
    required this.codEmpleado,
    required this.codEmpresa,
    required this.codCiudad,
    required this.login,
    required this.versionApp,
    required this.codSucursal,
  });

  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    return LoginDataModel(
      token: json['token'] ?? '',
      bearer: json['bearer'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      cargo: json['cargo'] ?? '',
      tipoUsuario: json['tipoUsuario'] ?? '',
      codUsuario: json['codUsuario'] ?? 0,
      codEmpleado: json['codEmpleado'] ?? 0,
      codEmpresa: json['codEmpresa'] ?? 0,
      codCiudad: json['codCiudad'] ?? 0,
      login: json['login'] ?? '',
      versionApp: json['versionApp'] ?? '',
      codSucursal: json['codSucursal'] ?? 0,
    );
  }
}