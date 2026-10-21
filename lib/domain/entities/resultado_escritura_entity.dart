/// Lo que devuelve una escritura de las pantallas de parámetros: el id que se
/// tocó y el texto que redactó el procedimiento almacenado para el usuario.
class ResultadoEscrituraEntity {
  final BigInt id;
  final String mensaje;

  const ResultadoEscrituraEntity({required this.id, required this.mensaje});
}
