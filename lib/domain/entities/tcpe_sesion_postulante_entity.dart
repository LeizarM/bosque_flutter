/// Respuesta del login del postulante (`/examen-publico/auth/login`).
class TcpeSesionPostulanteEntity {
  final String? token;
  final DateTime? expiracion;
  final BigInt? codUsuario;
  final String? login;
  /// Si es falso, antes de rendir completa CI, nombres y apellidos.
  final bool datosCompletos;
  final String? nombres;

  const TcpeSesionPostulanteEntity({
    this.token,
    this.expiracion,
    this.codUsuario,
    this.login,
    this.datosCompletos = false,
    this.nombres,
  });

  TcpeSesionPostulanteEntity copyWith({
    String? token,
    DateTime? expiracion,
    BigInt? codUsuario,
    String? login,
    bool? datosCompletos,
    String? nombres,
  }) => TcpeSesionPostulanteEntity(
    token: token ?? this.token,
    expiracion: expiracion ?? this.expiracion,
    codUsuario: codUsuario ?? this.codUsuario,
    login: login ?? this.login,
    datosCompletos: datosCompletos ?? this.datosCompletos,
    nombres: nombres ?? this.nombres,
  );
}
