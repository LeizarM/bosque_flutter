/// `tcpe_area`: Área de evaluación: agrupa las categorías del banco de preguntas.
/// Columnas de `p_list_tcpe_Area` (sin `password2`) más `nombreUsuario`.
class TcpeAreaEntity {
  final BigInt codArea;
  final String? nombreArea;
  final String? descripArea;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeAreaEntity({
    required this.codArea,
    this.nombreArea,
    this.descripArea,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeAreaEntity copyWith({
    BigInt? codArea,
    String? nombreArea,
    String? descripArea,
    bool? activo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeAreaEntity(
    codArea: codArea ?? this.codArea,
    nombreArea: nombreArea ?? this.nombreArea,
    descripArea: descripArea ?? this.descripArea,
    activo: activo ?? this.activo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
