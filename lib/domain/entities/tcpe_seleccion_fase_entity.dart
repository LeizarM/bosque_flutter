/// `tcpe_seleccionFase`: Fase elegida para una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_SeleccionFase` (sin `password2`) más `nombreUsuario`.
class TcpeSeleccionFaseEntity {
  final BigInt codSeleccionFase;
  final BigInt? codConvocatoria;
  final BigInt? codFase;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeSeleccionFaseEntity({
    required this.codSeleccionFase,
    this.codConvocatoria,
    this.codFase,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeSeleccionFaseEntity copyWith({
    BigInt? codSeleccionFase,
    BigInt? codConvocatoria,
    BigInt? codFase,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeSeleccionFaseEntity(
    codSeleccionFase: codSeleccionFase ?? this.codSeleccionFase,
    codConvocatoria: codConvocatoria ?? this.codConvocatoria,
    codFase: codFase ?? this.codFase,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
