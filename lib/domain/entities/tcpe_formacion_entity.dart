/// `tcpe_formacion`: Grado de formación académica (sin uso).
/// Columnas de `p_list_tcpe_Formacion` (sin `password2`) más `nombreUsuario`.
class TcpeFormacionEntity {
  final BigInt codFormacion;
  final String? nombreGrado;
  final String? grado;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeFormacionEntity({
    required this.codFormacion,
    this.nombreGrado,
    this.grado,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeFormacionEntity copyWith({
    BigInt? codFormacion,
    String? nombreGrado,
    String? grado,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeFormacionEntity(
    codFormacion: codFormacion ?? this.codFormacion,
    nombreGrado: nombreGrado ?? this.nombreGrado,
    grado: grado ?? this.grado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
