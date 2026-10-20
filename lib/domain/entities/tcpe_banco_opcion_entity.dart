/// Opción de una pregunta cerrada del banco (`p_list_tcpe_Banco` O).
class TcpeBancoOpcionEntity {
  final BigInt codRsptaOp;
  final BigInt? codRespuesta;
  final BigInt? codPregunta;
  final String? opcionRspta;
  final bool esValido;
  final bool usadaEnExamenes;

  const TcpeBancoOpcionEntity({
    required this.codRsptaOp,
    this.codRespuesta,
    this.codPregunta,
    this.opcionRspta,
    this.esValido = false,
    this.usadaEnExamenes = false,
  });

  TcpeBancoOpcionEntity copyWith({
    BigInt? codRsptaOp,
    BigInt? codRespuesta,
    BigInt? codPregunta,
    String? opcionRspta,
    bool? esValido,
    bool? usadaEnExamenes,
  }) => TcpeBancoOpcionEntity(
    codRsptaOp: codRsptaOp ?? this.codRsptaOp,
    codRespuesta: codRespuesta ?? this.codRespuesta,
    codPregunta: codPregunta ?? this.codPregunta,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    esValido: esValido ?? this.esValido,
    usadaEnExamenes: usadaEnExamenes ?? this.usadaEnExamenes,
  );
}
