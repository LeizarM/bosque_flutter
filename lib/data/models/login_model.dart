

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

  LoginEntity toEntity() {
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
        esAutorizador: data!.esAutorizador,
        estado: data!.estado,
        audUsuarioI: data!.audUsuarioI,
        nombreSucursal: data!.nombreSucursal,
        nombreCiudad: data!.nombreCiudad,
        nombreEmpresa: data!.nombreEmpresa,
      );
    } else {
      return LoginEntity(
        token: '',
        bearer: '',
        nombreCompleto: '',
        cargo: '',
        tipoUsuario: '',
        codUsuario: 0,
        codEmpleado: 0,
        codEmpresa: 0,
        codCiudad: 0,
        login: '',
        versionApp: '',
        codSucursal: 0,
        esAutorizador: '',
        estado: '',
        audUsuarioI: 0,
        nombreSucursal: '',
        nombreCiudad: '',
        nombreEmpresa: '',
      );
    }
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
  final String esAutorizador;
  final String estado;
  final int audUsuarioI;
  final String nombreSucursal;
  final String nombreCiudad;
  final String nombreEmpresa;

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
    required this.esAutorizador,
    required this.estado,
    required this.audUsuarioI,
    required this.nombreSucursal,
    required this.nombreCiudad,
    required this.nombreEmpresa,
    //... other fields if needed
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
      esAutorizador: json['esAutorizador'] ?? '',
      estado: json['estado'] ?? '',
      audUsuarioI: json['audUsuarioI'] ?? 0,
      nombreSucursal: json['nombreSucursal'] ?? '',
      nombreCiudad: json['nombreCiudad'] ?? '',
      nombreEmpresa: json['nombreEmpresa'] ?? '',
      //... other fields if needed
    );
  }
}