/// `tcpe_seleccionPreguntas`: Pregunta del banco sorteada para un examen.
/// Columnas de `p_list_tcpe_SeleccionPreguntas` (sin `password2`) más `nombreUsuario`.
class TcpeSeleccionPreguntasEntity {
  final BigInt codSeleccionPreguntas;
  final BigInt? codExamen;
  final BigInt? codPregunta;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeSeleccionPreguntasEntity({
    required this.codSeleccionPreguntas,
    this.codExamen,
    this.codPregunta,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeSeleccionPreguntasEntity copyWith({
    BigInt? codSeleccionPreguntas,
    BigInt? codExamen,
    BigInt? codPregunta,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeSeleccionPreguntasEntity(
    codSeleccionPreguntas: codSeleccionPreguntas ?? this.codSeleccionPreguntas,
    codExamen: codExamen ?? this.codExamen,
    codPregunta: codPregunta ?? this.codPregunta,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
