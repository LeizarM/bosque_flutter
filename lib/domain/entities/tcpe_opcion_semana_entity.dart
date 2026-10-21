/// Una opción de una pregunta de la semana vigente (`p_list_tcpe_PreguntaSemana`
/// O). [esValido] llega solo después de responder y si la pregunta muestra la
/// respuesta: antes es null y la UI no puede saber cuál es la correcta.
class TcpeOpcionSemanaEntity {
  final BigInt? codPreguntaSemana;
  final BigInt codRsptaOp;
  final String? opcionRspta;

  /// La que eligió quien mira.
  final bool elegida;
  final bool? esValido;

  const TcpeOpcionSemanaEntity({
    this.codPreguntaSemana,
    required this.codRsptaOp,
    this.opcionRspta,
    this.elegida = false,
    this.esValido,
  });

  TcpeOpcionSemanaEntity copyWith({
    BigInt? codPreguntaSemana,
    BigInt? codRsptaOp,
    String? opcionRspta,
    bool? elegida,
    bool? esValido,
  }) => TcpeOpcionSemanaEntity(
    codPreguntaSemana: codPreguntaSemana ?? this.codPreguntaSemana,
    codRsptaOp: codRsptaOp ?? this.codRsptaOp,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    elegida: elegida ?? this.elegida,
    esValido: esValido ?? this.esValido,
  );
}
