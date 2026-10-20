/// `tcpe_rsptaOpcionH`: Foto de una opción en un examen generado.
/// Columnas de `p_list_tcpe_RsptaOpcionH` (sin `password2`) más `nombreUsuario`.
class TcpeRsptaOpcionHEntity {
  final BigInt codRsptaOpH;
  final BigInt? codRespuestaH;
  final BigInt? codRespuesta;
  final BigInt? codRsptaOp;
  final String? opcionRspta;
  final bool esValido;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRsptaOpcionHEntity({
    required this.codRsptaOpH,
    this.codRespuestaH,
    this.codRespuesta,
    this.codRsptaOp,
    this.opcionRspta,
    this.esValido = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRsptaOpcionHEntity copyWith({
    BigInt? codRsptaOpH,
    BigInt? codRespuestaH,
    BigInt? codRespuesta,
    BigInt? codRsptaOp,
    String? opcionRspta,
    bool? esValido,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRsptaOpcionHEntity(
    codRsptaOpH: codRsptaOpH ?? this.codRsptaOpH,
    codRespuestaH: codRespuestaH ?? this.codRespuestaH,
    codRespuesta: codRespuesta ?? this.codRespuesta,
    codRsptaOp: codRsptaOp ?? this.codRsptaOp,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    esValido: esValido ?? this.esValido,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
