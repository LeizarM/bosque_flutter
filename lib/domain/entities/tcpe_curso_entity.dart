/// `tcpe_curso`: Curso de una capacitación (sin uso).
/// Columnas de `p_list_tcpe_Curso` (sin `password2`) más `nombreUsuario`.
class TcpeCursoEntity {
  final BigInt codCurso;
  final BigInt? codCapacitacion;
  final double? inversion;
  final String? titulo;
  final String? descripcion;
  final String? lugar;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeCursoEntity({
    required this.codCurso,
    this.codCapacitacion,
    this.inversion,
    this.titulo,
    this.descripcion,
    this.lugar,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeCursoEntity copyWith({
    BigInt? codCurso,
    BigInt? codCapacitacion,
    double? inversion,
    String? titulo,
    String? descripcion,
    String? lugar,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeCursoEntity(
    codCurso: codCurso ?? this.codCurso,
    codCapacitacion: codCapacitacion ?? this.codCapacitacion,
    inversion: inversion ?? this.inversion,
    titulo: titulo ?? this.titulo,
    descripcion: descripcion ?? this.descripcion,
    lugar: lugar ?? this.lugar,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
