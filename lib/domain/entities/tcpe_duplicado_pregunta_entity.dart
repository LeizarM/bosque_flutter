/// Una pregunta del banco igual o parecida al texto que se escribe
/// (`p_list_tcpe_Banco` D). [igual] es true si el texto normalizado coincide.
class TcpeDuplicadoPreguntaEntity {
  final BigInt codPregunta;
  final String? pregunta;
  final bool activo;
  final bool igual;

  const TcpeDuplicadoPreguntaEntity({required this.codPregunta, this.pregunta, this.activo = true, this.igual = false});

  TcpeDuplicadoPreguntaEntity copyWith({BigInt? codPregunta, String? pregunta, bool? activo, bool? igual}) =>
      TcpeDuplicadoPreguntaEntity(
        codPregunta: codPregunta ?? this.codPregunta,
        pregunta: pregunta ?? this.pregunta,
        activo: activo ?? this.activo,
        igual: igual ?? this.igual,
      );
}
