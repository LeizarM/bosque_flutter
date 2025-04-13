class LoginEntity {
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

  LoginEntity({
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

  factory LoginEntity.fromJson(Map<String, dynamic> json) {
    return LoginEntity(
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

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'bearer': bearer,
      'nombreCompleto': nombreCompleto,
      'cargo': cargo,
      'tipoUsuario': tipoUsuario,
      'codUsuario': codUsuario,
      'codEmpleado': codEmpleado,
      'codEmpresa': codEmpresa,
      'codCiudad': codCiudad,
      'login': login,
      'versionApp': versionApp,
      'codSucursal': codSucursal,
    };
  }
}