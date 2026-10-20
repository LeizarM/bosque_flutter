/// `tcpe_experienciaLab`: Experiencia laboral pedida por una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_ExperienciaLab` (sin `password2`) más `nombreUsuario`.
class TcpeExperienciaLabEntity {
  final BigInt codExpLab;
  final BigInt? codConvocatoria;
  final int? cantidad;
  final String? medida;
  final String? ocupacion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeExperienciaLabEntity({
    required this.codExpLab,
    this.codConvocatoria,
    this.cantidad,
    this.medida,
    this.ocupacion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeExperienciaLabEntity copyWith({
    BigInt? codExpLab,
    BigInt? codConvocatoria,
    int? cantidad,
    String? medida,
    String? ocupacion,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeExperienciaLabEntity(
    codExpLab: codExpLab ?? this.codExpLab,
    codConvocatoria: codConvocatoria ?? this.codConvocatoria,
    cantidad: cantidad ?? this.cantidad,
    medida: medida ?? this.medida,
    ocupacion: ocupacion ?? this.ocupacion,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
