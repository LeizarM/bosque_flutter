/// `tcpe_areaPost`: Área de una postulación (módulo de convocatorias, hoy sin uso).
/// Columnas de `p_list_tcpe_AreaPost` (sin `password2`) más `nombreUsuario`.
class TcpeAreaPostEntity {
  final BigInt codAreaPost;
  final String? nombArea;
  final BigInt? codTipo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeAreaPostEntity({
    required this.codAreaPost,
    this.nombArea,
    this.codTipo,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeAreaPostEntity copyWith({
    BigInt? codAreaPost,
    String? nombArea,
    BigInt? codTipo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeAreaPostEntity(
    codAreaPost: codAreaPost ?? this.codAreaPost,
    nombArea: nombArea ?? this.nombArea,
    codTipo: codTipo ?? this.codTipo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
