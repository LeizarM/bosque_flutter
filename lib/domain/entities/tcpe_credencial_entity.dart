/// Login y clave temporal en claro de un examen recién generado o regenerada.
/// La clave solo existe en esta respuesta: en la base queda el hash.
class TcpeCredencialEntity {
  final BigInt? codExamen;
  final BigInt? codUsuario;
  final String? login;
  final String? password;
  final String? ci;
  final String? nombreCompleto;
  final BigInt? codEmpleado;

  const TcpeCredencialEntity({
    this.codExamen,
    this.codUsuario,
    this.login,
    this.password,
    this.ci,
    this.nombreCompleto,
    this.codEmpleado,
  });

  TcpeCredencialEntity copyWith({
    BigInt? codExamen,
    BigInt? codUsuario,
    String? login,
    String? password,
    String? ci,
    String? nombreCompleto,
    BigInt? codEmpleado,
  }) => TcpeCredencialEntity(
    codExamen: codExamen ?? this.codExamen,
    codUsuario: codUsuario ?? this.codUsuario,
    login: login ?? this.login,
    password: password ?? this.password,
    ci: ci ?? this.ci,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    codEmpleado: codEmpleado ?? this.codEmpleado,
  );

  /// Un empleado entra con su usuario de Bosque y un escrito no tiene usuario:
  /// ninguno de los dos recibe clave.
  bool get tieneClave => (password ?? '').isNotEmpty;
}
