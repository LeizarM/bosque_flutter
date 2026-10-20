/// `tcpe_otrosConocimientos`: Conocimiento declarado por un postulante (sin uso).
/// Columnas de `p_list_tcpe_OtrosConocimientos` (sin `password2`) más `nombreUsuario`.
class TcpeOtrosConocimientosEntity {
  final BigInt codOtrosCono;
  final BigInt? codPersonaPost;
  final BigInt? codConocimiento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeOtrosConocimientosEntity({
    required this.codOtrosCono,
    this.codPersonaPost,
    this.codConocimiento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeOtrosConocimientosEntity copyWith({
    BigInt? codOtrosCono,
    BigInt? codPersonaPost,
    BigInt? codConocimiento,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeOtrosConocimientosEntity(
    codOtrosCono: codOtrosCono ?? this.codOtrosCono,
    codPersonaPost: codPersonaPost ?? this.codPersonaPost,
    codConocimiento: codConocimiento ?? this.codConocimiento,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
