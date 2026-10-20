/// `tcpe_rsptaOpcionU`: Opción que marcó el usuario al rendir.
/// Columnas de `p_list_tcpe_RsptaOpcionU` (sin `password2`) más `nombreUsuario`.
class TcpeRsptaOpcionUEntity {
  final BigInt codRsptaOpU;
  final BigInt? codRsptaOpH;
  final BigInt? codExamen;
  final BigInt? codRespuesta;
  final BigInt? codRsptaOp;
  final String? opcionRspta;
  final bool esValido;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeRsptaOpcionUEntity({
    required this.codRsptaOpU,
    this.codRsptaOpH,
    this.codExamen,
    this.codRespuesta,
    this.codRsptaOp,
    this.opcionRspta,
    this.esValido = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeRsptaOpcionUEntity copyWith({
    BigInt? codRsptaOpU,
    BigInt? codRsptaOpH,
    BigInt? codExamen,
    BigInt? codRespuesta,
    BigInt? codRsptaOp,
    String? opcionRspta,
    bool? esValido,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeRsptaOpcionUEntity(
    codRsptaOpU: codRsptaOpU ?? this.codRsptaOpU,
    codRsptaOpH: codRsptaOpH ?? this.codRsptaOpH,
    codExamen: codExamen ?? this.codExamen,
    codRespuesta: codRespuesta ?? this.codRespuesta,
    codRsptaOp: codRsptaOp ?? this.codRsptaOp,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    esValido: esValido ?? this.esValido,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
