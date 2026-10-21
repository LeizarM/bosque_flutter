/// Quién respondió una pregunta de la semana y qué escribió
/// (`p_list_tcpe_PreguntaSemana` R): nombre como en el login y cargo actual.
class TcpeRespondioSemanaEntity {
  final BigInt codRsptaSemana;
  final BigInt? codUsuario;
  final String? login;
  final String? nombreCompleto;
  final String? cargo;
  final String? respuesta;
  final DateTime? fechaRespuesta;

  const TcpeRespondioSemanaEntity({
    required this.codRsptaSemana,
    this.codUsuario,
    this.login,
    this.nombreCompleto,
    this.cargo,
    this.respuesta,
    this.fechaRespuesta,
  });

  TcpeRespondioSemanaEntity copyWith({
    BigInt? codRsptaSemana,
    BigInt? codUsuario,
    String? login,
    String? nombreCompleto,
    String? cargo,
    String? respuesta,
    DateTime? fechaRespuesta,
  }) => TcpeRespondioSemanaEntity(
    codRsptaSemana: codRsptaSemana ?? this.codRsptaSemana,
    codUsuario: codUsuario ?? this.codUsuario,
    login: login ?? this.login,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    cargo: cargo ?? this.cargo,
    respuesta: respuesta ?? this.respuesta,
    fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
  );
}
