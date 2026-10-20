/// `tcpe_empleado`: Empleado habilitado en el módulo (el PK es el de tb_empleado).
/// Columnas de `p_list_tcpe_Empleado` (sin `password2`) más `nombreUsuario`.
/// `codEmpleado` no es IDENTITY: en 0 el SP toma el siguiente número.
class TcpeEmpleadoEntity {
  final BigInt codEmpleado;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeEmpleadoEntity({
    required this.codEmpleado,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeEmpleadoEntity copyWith({
    BigInt? codEmpleado,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeEmpleadoEntity(
    codEmpleado: codEmpleado ?? this.codEmpleado,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
