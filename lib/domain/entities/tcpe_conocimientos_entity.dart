/// `tcpe_conocimientos`: Conocimiento pedido por una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_Conocimientos` (sin `password2`) más `nombreUsuario`.
class TcpeConocimientosEntity {
  final BigInt codConocimiento;
  final BigInt? codConvocatoria;
  final String? grado;
  final String? conocimiento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeConocimientosEntity({
    required this.codConocimiento,
    this.codConvocatoria,
    this.grado,
    this.conocimiento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeConocimientosEntity copyWith({
    BigInt? codConocimiento,
    BigInt? codConvocatoria,
    String? grado,
    String? conocimiento,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeConocimientosEntity(
    codConocimiento: codConocimiento ?? this.codConocimiento,
    codConvocatoria: codConvocatoria ?? this.codConvocatoria,
    grado: grado ?? this.grado,
    conocimiento: conocimiento ?? this.conocimiento,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
