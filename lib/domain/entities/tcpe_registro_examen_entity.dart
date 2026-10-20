/// `tcpe_registroExamen`: Opción marcada en un examen del sistema anterior.
/// Columnas de `p_list_tcpe_RegistroExamen` (sin `password2`) más `nombreUsuario`.
class TcpeRegistroExamenEntity {
  final BigInt codRegExamen;
  final BigInt? codExamen;
  final BigInt? codRsptaOpcion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRegistroExamenEntity({
    required this.codRegExamen,
    this.codExamen,
    this.codRsptaOpcion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRegistroExamenEntity copyWith({
    BigInt? codRegExamen,
    BigInt? codExamen,
    BigInt? codRsptaOpcion,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRegistroExamenEntity(
    codRegExamen: codRegExamen ?? this.codRegExamen,
    codExamen: codExamen ?? this.codExamen,
    codRsptaOpcion: codRsptaOpcion ?? this.codRsptaOpcion,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
