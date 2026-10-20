/// Una opción (o la pregunta abierta) de un examen, para los PDF (`p_list_tcpe_Resultado` S).
class TcpeSolucionarioItemEntity {
  final BigInt? codExamen;
  final BigInt? codPreguntaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;
  final BigInt? codRsptaOpH;
  final String? opcionRspta;
  final bool esValido;

  const TcpeSolucionarioItemEntity({
    this.codExamen,
    this.codPreguntaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.codRsptaOpH,
    this.opcionRspta,
    this.esValido = false,
  });

  TcpeSolucionarioItemEntity copyWith({
    BigInt? codExamen,
    BigInt? codPreguntaH,
    int? orden,
    String? pregunta,
    bool? esCerrada,
    BigInt? codRsptaOpH,
    String? opcionRspta,
    bool? esValido,
  }) => TcpeSolucionarioItemEntity(
    codExamen: codExamen ?? this.codExamen,
    codPreguntaH: codPreguntaH ?? this.codPreguntaH,
    orden: orden ?? this.orden,
    pregunta: pregunta ?? this.pregunta,
    esCerrada: esCerrada ?? this.esCerrada,
    codRsptaOpH: codRsptaOpH ?? this.codRsptaOpH,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    esValido: esValido ?? this.esValido,
  );
}
