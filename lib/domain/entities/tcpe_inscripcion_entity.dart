/// `tcpe_inscripcion`: Inscripción a una capacitación (sin uso).
/// Columnas de `p_list_tcpe_Inscripcion` (sin `password2`) más `nombreUsuario`.
class TcpeInscripcionEntity {
  final BigInt codInscripcion;
  final BigInt? codCapacitacion;
  final BigInt? codUsuario;
  final String? observaciones;
  final DateTime? fechaInscrip;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeInscripcionEntity({
    required this.codInscripcion,
    this.codCapacitacion,
    this.codUsuario,
    this.observaciones,
    this.fechaInscrip,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeInscripcionEntity copyWith({
    BigInt? codInscripcion,
    BigInt? codCapacitacion,
    BigInt? codUsuario,
    String? observaciones,
    DateTime? fechaInscrip,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeInscripcionEntity(
    codInscripcion: codInscripcion ?? this.codInscripcion,
    codCapacitacion: codCapacitacion ?? this.codCapacitacion,
    codUsuario: codUsuario ?? this.codUsuario,
    observaciones: observaciones ?? this.observaciones,
    fechaInscrip: fechaInscrip ?? this.fechaInscrip,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
