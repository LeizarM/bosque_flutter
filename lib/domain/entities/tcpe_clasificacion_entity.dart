/// `tcpe_clasificacion`: Categoría del banco de preguntas, dentro de un área.
/// Columnas de `p_list_tcpe_Clasificacion` (sin `password2`) más `nombreUsuario`.
class TcpeClasificacionEntity {
  final BigInt codClasificacion;
  final BigInt? codArea;
  final BigInt? codCurso;
  final String? nombre;
  final String? modalidad;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeClasificacionEntity({
    required this.codClasificacion,
    this.codArea,
    this.codCurso,
    this.nombre,
    this.modalidad,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeClasificacionEntity copyWith({
    BigInt? codClasificacion,
    BigInt? codArea,
    BigInt? codCurso,
    String? nombre,
    String? modalidad,
    bool? activo,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeClasificacionEntity(
    codClasificacion: codClasificacion ?? this.codClasificacion,
    codArea: codArea ?? this.codArea,
    codCurso: codCurso ?? this.codCurso,
    nombre: nombre ?? this.nombre,
    modalidad: modalidad ?? this.modalidad,
    activo: activo ?? this.activo,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
