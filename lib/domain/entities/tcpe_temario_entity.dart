/// `tcpe_temario`: Temario de un curso (sin uso).
/// Columnas de `p_list_tcpe_Temario` (sin `password2`) más `nombreUsuario`.
class TcpeTemarioEntity {
  final BigInt codTemario;
  final BigInt? codCurso;
  final BigInt? codCapacitador;
  final String? nombre;
  final String? descripcion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeTemarioEntity({
    required this.codTemario,
    this.codCurso,
    this.codCapacitador,
    this.nombre,
    this.descripcion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeTemarioEntity copyWith({
    BigInt? codTemario,
    BigInt? codCurso,
    BigInt? codCapacitador,
    String? nombre,
    String? descripcion,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeTemarioEntity(
    codTemario: codTemario ?? this.codTemario,
    codCurso: codCurso ?? this.codCurso,
    codCapacitador: codCapacitador ?? this.codCapacitador,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
