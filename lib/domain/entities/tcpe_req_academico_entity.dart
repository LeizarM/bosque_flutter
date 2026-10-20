/// `tcpe_reqAcademico`: Requisito académico de una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_ReqAcademico` (sin `password2`) más `nombreUsuario`.
class TcpeReqAcademicoEntity {
  final BigInt codReqAcademico;
  final BigInt? codConvocatoria;
  final BigInt? codFormacion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeReqAcademicoEntity({
    required this.codReqAcademico,
    this.codConvocatoria,
    this.codFormacion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeReqAcademicoEntity copyWith({
    BigInt? codReqAcademico,
    BigInt? codConvocatoria,
    BigInt? codFormacion,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeReqAcademicoEntity(
    codReqAcademico: codReqAcademico ?? this.codReqAcademico,
    codConvocatoria: codConvocatoria ?? this.codConvocatoria,
    codFormacion: codFormacion ?? this.codFormacion,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
