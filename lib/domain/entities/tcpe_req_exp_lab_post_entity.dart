/// `tcpe_reqExpLabPost`: Experiencia declarada por un postulante (sin uso).
/// Columnas de `p_list_tcpe_ReqExpLabPost` (sin `password2`) más `nombreUsuario`.
class TcpeReqExpLabPostEntity {
  final BigInt codExpLabPost;
  final BigInt? codPersonaPost;
  final String? nombreEmpresa;
  final String? cargo;
  final String? descripcion;
  final DateTime? fechaFin;
  final DateTime? fechaInicio;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeReqExpLabPostEntity({
    required this.codExpLabPost,
    this.codPersonaPost,
    this.nombreEmpresa,
    this.cargo,
    this.descripcion,
    this.fechaFin,
    this.fechaInicio,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeReqExpLabPostEntity copyWith({
    BigInt? codExpLabPost,
    BigInt? codPersonaPost,
    String? nombreEmpresa,
    String? cargo,
    String? descripcion,
    DateTime? fechaFin,
    DateTime? fechaInicio,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeReqExpLabPostEntity(
    codExpLabPost: codExpLabPost ?? this.codExpLabPost,
    codPersonaPost: codPersonaPost ?? this.codPersonaPost,
    nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
    cargo: cargo ?? this.cargo,
    descripcion: descripcion ?? this.descripcion,
    fechaFin: fechaFin ?? this.fechaFin,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
