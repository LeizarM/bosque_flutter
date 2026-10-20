/// `tcpe_dpto`: Departamento (sin uso).
/// Columnas de `p_list_tcpe_Dpto` (sin `password2`) más `nombreUsuario`.
class TcpeDptoEntity {
  final BigInt codDpto;
  final String? departamento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeDptoEntity({
    required this.codDpto,
    this.departamento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeDptoEntity copyWith({
    BigInt? codDpto,
    String? departamento,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeDptoEntity(
    codDpto: codDpto ?? this.codDpto,
    departamento: departamento ?? this.departamento,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
