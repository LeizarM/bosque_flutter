/// `tcpe_capacitacion`: Capacitación (módulo de capacitaciones, hoy sin uso).
/// Columnas de `p_list_tcpe_Capacitacion` (sin `password2`) más `nombreUsuario`.
class TcpeCapacitacionEntity {
  final BigInt codCapacitacion;
  final bool? esInterna;
  final String? titulo;
  final String? descripcion;
  final String? objetivo;
  final String? telfReferencia;
  final String? destinatarios;
  final DateTime? proFechaInicio;
  final DateTime? proFechaFin;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeCapacitacionEntity({
    required this.codCapacitacion,
    this.esInterna,
    this.titulo,
    this.descripcion,
    this.objetivo,
    this.telfReferencia,
    this.destinatarios,
    this.proFechaInicio,
    this.proFechaFin,
    this.fechaInicio,
    this.fechaFin,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeCapacitacionEntity copyWith({
    BigInt? codCapacitacion,
    bool? esInterna,
    String? titulo,
    String? descripcion,
    String? objetivo,
    String? telfReferencia,
    String? destinatarios,
    DateTime? proFechaInicio,
    DateTime? proFechaFin,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeCapacitacionEntity(
    codCapacitacion: codCapacitacion ?? this.codCapacitacion,
    esInterna: esInterna ?? this.esInterna,
    titulo: titulo ?? this.titulo,
    descripcion: descripcion ?? this.descripcion,
    objetivo: objetivo ?? this.objetivo,
    telfReferencia: telfReferencia ?? this.telfReferencia,
    destinatarios: destinatarios ?? this.destinatarios,
    proFechaInicio: proFechaInicio ?? this.proFechaInicio,
    proFechaFin: proFechaFin ?? this.proFechaFin,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
