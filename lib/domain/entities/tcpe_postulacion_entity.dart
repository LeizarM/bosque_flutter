/// `tcpe_postulacion`: Postulación a una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_Postulacion` (sin `password2`) más `nombreUsuario`.
/// `codPostulacion` no es IDENTITY: en 0 el SP toma el siguiente número.
class TcpePostulacionEntity {
  final BigInt codPostulacion;
  final BigInt? codPersonaPost;
  final BigInt? codConvocatoria;
  final DateTime? fechaPost;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpePostulacionEntity({
    required this.codPostulacion,
    this.codPersonaPost,
    this.codConvocatoria,
    this.fechaPost,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpePostulacionEntity copyWith({
    BigInt? codPostulacion,
    BigInt? codPersonaPost,
    BigInt? codConvocatoria,
    DateTime? fechaPost,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpePostulacionEntity(
    codPostulacion: codPostulacion ?? this.codPostulacion,
    codPersonaPost: codPersonaPost ?? this.codPersonaPost,
    codConvocatoria: codConvocatoria ?? this.codConvocatoria,
    fechaPost: fechaPost ?? this.fechaPost,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
