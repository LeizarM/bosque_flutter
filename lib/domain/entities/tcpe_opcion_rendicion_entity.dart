/// Opción de una pregunta cerrada en curso (`p_list_tcpe_Rendir` O).
/// Nunca trae `esValido`: quien rinde no puede saber cuál es la correcta.
class TcpeOpcionRendicionEntity {
  final BigInt codRsptaOpH;
  final BigInt? codPreguntaH;
  final String? opcionRspta;
  final bool marcada;

  const TcpeOpcionRendicionEntity({
    required this.codRsptaOpH,
    this.codPreguntaH,
    this.opcionRspta,
    this.marcada = false,
  });

  TcpeOpcionRendicionEntity copyWith({
    BigInt? codRsptaOpH,
    BigInt? codPreguntaH,
    String? opcionRspta,
    bool? marcada,
  }) => TcpeOpcionRendicionEntity(
    codRsptaOpH: codRsptaOpH ?? this.codRsptaOpH,
    codPreguntaH: codPreguntaH ?? this.codPreguntaH,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    marcada: marcada ?? this.marcada,
  );
}
