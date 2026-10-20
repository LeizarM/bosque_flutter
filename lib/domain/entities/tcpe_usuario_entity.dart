/// `tcpe_usuario`: Usuario del módulo: empleado evaluado o postulante externo (login IPX-n).
/// Columnas de `p_list_tcpe_Usuario` (sin `password2`) más `nombreUsuario`.
class TcpeUsuarioEntity {
  final BigInt codUsuario;
  final BigInt? codEmpleado;
  final BigInt? codTipoUsuario;
  final String? ci;
  final BigInt? codArea;
  final String? nombres;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? login;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeUsuarioEntity({
    required this.codUsuario,
    this.codEmpleado,
    this.codTipoUsuario,
    this.ci,
    this.codArea,
    this.nombres,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.login,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeUsuarioEntity copyWith({
    BigInt? codUsuario,
    BigInt? codEmpleado,
    BigInt? codTipoUsuario,
    String? ci,
    BigInt? codArea,
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? login,
    bool? activo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeUsuarioEntity(
    codUsuario: codUsuario ?? this.codUsuario,
    codEmpleado: codEmpleado ?? this.codEmpleado,
    codTipoUsuario: codTipoUsuario ?? this.codTipoUsuario,
    ci: ci ?? this.ci,
    codArea: codArea ?? this.codArea,
    nombres: nombres ?? this.nombres,
    apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
    apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
    login: login ?? this.login,
    activo: activo ?? this.activo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
