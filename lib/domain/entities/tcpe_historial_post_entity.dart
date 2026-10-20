/// `tcpe_historialPost`: Historial de fases de una postulación (sin uso).
/// Columnas de `p_list_tcpe_HistorialPost` (sin `password2`) más `nombreUsuario`.
class TcpeHistorialPostEntity {
  final BigInt codHistorialPost;
  final BigInt? codFase;
  final BigInt? codPostulacion;
  final DateTime? fechaHistorial;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeHistorialPostEntity({
    required this.codHistorialPost,
    this.codFase,
    this.codPostulacion,
    this.fechaHistorial,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeHistorialPostEntity copyWith({
    BigInt? codHistorialPost,
    BigInt? codFase,
    BigInt? codPostulacion,
    DateTime? fechaHistorial,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeHistorialPostEntity(
    codHistorialPost: codHistorialPost ?? this.codHistorialPost,
    codFase: codFase ?? this.codFase,
    codPostulacion: codPostulacion ?? this.codPostulacion,
    fechaHistorial: fechaHistorial ?? this.fechaHistorial,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
