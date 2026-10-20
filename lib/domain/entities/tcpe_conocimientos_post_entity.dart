/// `tcpe_conocimientosPost`: Catálogo de conocimientos de un postulante (sin uso).
/// Columnas de `p_list_tcpe_ConocimientosPost` (sin `password2`) más `nombreUsuario`.
/// `codConocimiento` no es IDENTITY: en 0 el SP toma el siguiente número.
class TcpeConocimientosPostEntity {
  final BigInt codConocimiento;
  final String? nombreConocimiento;
  final bool? esVigente;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeConocimientosPostEntity({
    required this.codConocimiento,
    this.nombreConocimiento,
    this.esVigente,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeConocimientosPostEntity copyWith({
    BigInt? codConocimiento,
    String? nombreConocimiento,
    bool? esVigente,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeConocimientosPostEntity(
    codConocimiento: codConocimiento ?? this.codConocimiento,
    nombreConocimiento: nombreConocimiento ?? this.nombreConocimiento,
    esVigente: esVigente ?? this.esVigente,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
