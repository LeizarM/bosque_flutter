/// `tcpe_rsptaOpcion`: Opción de una pregunta cerrada del banco.
/// Columnas de `p_list_tcpe_RsptaOpcion` (sin `password2`) más `nombreUsuario`.
class TcpeRsptaOpcionEntity {
  final BigInt codRsptaOp;
  final BigInt? codRespuesta;
  final String? opcionRspta;
  final bool esValido;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRsptaOpcionEntity({
    required this.codRsptaOp,
    this.codRespuesta,
    this.opcionRspta,
    this.esValido = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRsptaOpcionEntity copyWith({
    BigInt? codRsptaOp,
    BigInt? codRespuesta,
    String? opcionRspta,
    bool? esValido,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRsptaOpcionEntity(
    codRsptaOp: codRsptaOp ?? this.codRsptaOp,
    codRespuesta: codRespuesta ?? this.codRespuesta,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    esValido: esValido ?? this.esValido,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
