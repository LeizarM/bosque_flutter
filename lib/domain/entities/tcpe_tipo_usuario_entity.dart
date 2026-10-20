/// `tcpe_tipoUsuario`: Tipo de usuario del módulo (2 = evaluado).
/// Columnas de `p_list_tcpe_TipoUsuario` (sin `password2`) más `nombreUsuario`.
class TcpeTipoUsuarioEntity {
  final BigInt codTipoUsuario;
  final String? tipo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeTipoUsuarioEntity({
    required this.codTipoUsuario,
    this.tipo,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeTipoUsuarioEntity copyWith({
    BigInt? codTipoUsuario,
    String? tipo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeTipoUsuarioEntity(
    codTipoUsuario: codTipoUsuario ?? this.codTipoUsuario,
    tipo: tipo ?? this.tipo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
