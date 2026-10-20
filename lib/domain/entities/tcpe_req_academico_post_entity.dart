/// `tcpe_reqAcademicoPost`: Formación declarada por un postulante (sin uso).
/// Columnas de `p_list_tcpe_ReqAcademicoPost` (sin `password2`) más `nombreUsuario`.
class TcpeReqAcademicoPostEntity {
  final BigInt codReqAcaPost;
  final BigInt? codPersonaPost;
  final BigInt? codFormacion;
  final int? gestion;
  final String? nomInstitucion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeReqAcademicoPostEntity({
    required this.codReqAcaPost,
    this.codPersonaPost,
    this.codFormacion,
    this.gestion,
    this.nomInstitucion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeReqAcademicoPostEntity copyWith({
    BigInt? codReqAcaPost,
    BigInt? codPersonaPost,
    BigInt? codFormacion,
    int? gestion,
    String? nomInstitucion,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeReqAcademicoPostEntity(
    codReqAcaPost: codReqAcaPost ?? this.codReqAcaPost,
    codPersonaPost: codPersonaPost ?? this.codPersonaPost,
    codFormacion: codFormacion ?? this.codFormacion,
    gestion: gestion ?? this.gestion,
    nomInstitucion: nomInstitucion ?? this.nomInstitucion,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
