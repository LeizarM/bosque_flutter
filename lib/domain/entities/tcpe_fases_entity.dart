/// `tcpe_fases`: Fase de una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_Fases` (sin `password2`) más `nombreUsuario`.
class TcpeFasesEntity {
  final BigInt codFase;
  final String? nombre;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeFasesEntity({
    required this.codFase,
    this.nombre,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeFasesEntity copyWith({
    BigInt? codFase,
    String? nombre,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeFasesEntity(
    codFase: codFase ?? this.codFase,
    nombre: nombre ?? this.nombre,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
