/// Quién respondió una pregunta de la semana y qué eligió
/// (`p_list_tcpe_PreguntaSemana` R): nombre como en el login y cargo actual.
class TcpeRespondioSemanaEntity {
  final BigInt codRsptaSemana;
  final BigInt? codUsuario;
  final String? login;
  final String? nombreCompleto;
  final String? cargo;
  final BigInt? codRsptaOp;
  final String? opcionRspta;
  final bool esCorrecta;
  final DateTime? fechaRespuesta;

  const TcpeRespondioSemanaEntity({
    required this.codRsptaSemana,
    this.codUsuario,
    this.login,
    this.nombreCompleto,
    this.cargo,
    this.codRsptaOp,
    this.opcionRspta,
    this.esCorrecta = false,
    this.fechaRespuesta,
  });

  TcpeRespondioSemanaEntity copyWith({
    BigInt? codRsptaSemana,
    BigInt? codUsuario,
    String? login,
    String? nombreCompleto,
    String? cargo,
    BigInt? codRsptaOp,
    String? opcionRspta,
    bool? esCorrecta,
    DateTime? fechaRespuesta,
  }) => TcpeRespondioSemanaEntity(
    codRsptaSemana: codRsptaSemana ?? this.codRsptaSemana,
    codUsuario: codUsuario ?? this.codUsuario,
    login: login ?? this.login,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    cargo: cargo ?? this.cargo,
    codRsptaOp: codRsptaOp ?? this.codRsptaOp,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    esCorrecta: esCorrecta ?? this.esCorrecta,
    fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
  );
}
