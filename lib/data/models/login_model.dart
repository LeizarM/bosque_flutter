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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {
      'mensaje': mensaje,
      'status': status,
    };
    if (data != null) dataMap['data'] = data!.toJson();
    return dataMap;
  }

  LoginEntity toEntity() {
    if (data != null) {
      return data!.toEntity();
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
        npassword: '',
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
  String npassword;

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
    required this.npassword,
  });

  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    // Mapeo seguro para cargo anidado
    String cargo = '';
    try {
      cargo = json['empleado']?['empleadoCargo']?['cargoSucursal']?['cargo']?['descripcion'] ?? '';
    } catch (_) {
      cargo = '';
    }

    return LoginDataModel(
      token: json['token'] ?? '',
      bearer: json['bearer'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      cargo: cargo,
      tipoUsuario: json['tipoUsuario'] ?? '',
      codUsuario: json['codUsuario'] ?? json['codusuario'] ?? 0,
      codEmpleado: json['codEmpleado'] ?? json['codempleado'] ?? 0,
      codEmpresa: json['codEmpresa'] ?? json['codempresa'] ?? 0,
      codCiudad: json['codCiudad'] ?? json['codciudad'] ?? 0,
      login: json['login'] ?? '',
      versionApp: json['versionApp'] ?? '',
      codSucursal: json['codSucursal'] ?? json['codsucursal'] ?? 0,
      esAutorizador: json['esAutorizador'] ?? '',
      estado: json['estado'] ?? '',
      audUsuarioI: json['audUsuarioI'] ?? 0,
      nombreSucursal: json['nombreSucursal'] ?? '',
      nombreCiudad: json['nombreCiudad'] ?? '',
      nombreEmpresa: json['nombreEmpresa'] ?? '',
      npassword: json['npassword'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (token.isNotEmpty) data['token'] = token;
    if (bearer.isNotEmpty) data['bearer'] = bearer;
    if (nombreCompleto.isNotEmpty) data['nombreCompleto'] = nombreCompleto;
    if (cargo.isNotEmpty) data['cargo'] = cargo;
    if (tipoUsuario.isNotEmpty) data['tipoUsuario'] = tipoUsuario;
    if (codUsuario != 0) data['codUsuario'] = codUsuario;
    if (codEmpleado != 0) data['codEmpleado'] = codEmpleado;
    if (codEmpresa != 0) data['codEmpresa'] = codEmpresa;
    if (codCiudad != 0) data['codCiudad'] = codCiudad;
    if (login.isNotEmpty) data['login'] = login;
    if (versionApp.isNotEmpty) data['versionApp'] = versionApp;
    if (codSucursal != 0) data['codSucursal'] = codSucursal;
    if (esAutorizador.isNotEmpty) data['esAutorizador'] = esAutorizador;
    if (estado.isNotEmpty) data['estado'] = estado;
    if (audUsuarioI != 0) data['audUsuarioI'] = audUsuarioI;
    if (nombreSucursal.isNotEmpty) data['nombreSucursal'] = nombreSucursal;
    if (nombreCiudad.isNotEmpty) data['nombreCiudad'] = nombreCiudad;
    if (nombreEmpresa.isNotEmpty) data['nombreEmpresa'] = nombreEmpresa;
    return data;
  }

  LoginEntity toEntity() {
    return LoginEntity(
      token: token,
      bearer: bearer,
      nombreCompleto: nombreCompleto,
      cargo: cargo,
      tipoUsuario: tipoUsuario,
      codUsuario: codUsuario,
      codEmpleado: codEmpleado,
      codEmpresa: codEmpresa,
      codCiudad: codCiudad,
      login: login,
      versionApp: versionApp,
      codSucursal: codSucursal,
      esAutorizador: esAutorizador,
      estado: estado,
      audUsuarioI: audUsuarioI,
      nombreSucursal: nombreSucursal,
      nombreCiudad: nombreCiudad,
      nombreEmpresa: nombreEmpresa,
      npassword: npassword,

    );
  }
}