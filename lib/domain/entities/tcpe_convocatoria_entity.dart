/// `tcpe_convocatoria`: Convocatoria a un puesto (sin uso).
/// Columnas de `p_list_tcpe_Convocatoria` (sin `password2`) más `nombreUsuario`.
class TcpeConvocatoriaEntity {
  final BigInt codConvocatoria;
  final BigInt? codArea;
  final BigInt? codDpto;
  final DateTime? gestion;
  final bool? esInterna;
  final String? titulo;
  final String? observacion;
  final String? descripcion;
  final String? nombrePuesto;
  final String? competencias;
  final String? objCargo;
  final String? funciones;
  final String? estado;
  final DateTime? proFechaInicio;
  final DateTime? proFechaFin;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  /// Login de `tb_usuario` según `audUsuario` (solo lectura).
  final String? nombreUsuario;

  const TcpeConvocatoriaEntity({
    required this.codConvocatoria,
    this.codArea,
    this.codDpto,
    this.gestion,
    this.esInterna,
    this.titulo,
    this.observacion,
    this.descripcion,
    this.nombrePuesto,
    this.competencias,
    this.objCargo,
    this.funciones,
    this.estado,
    this.proFechaInicio,
    this.proFechaFin,
    this.fechaInicio,
    this.fechaFin,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  TcpeConvocatoriaEntity copyWith({
    BigInt? codConvocatoria,
    BigInt? codArea,
    BigInt? codDpto,
    DateTime? gestion,
    bool? esInterna,
    String? titulo,
    String? observacion,
    String? descripcion,
    String? nombrePuesto,
    String? competencias,
    String? objCargo,
    String? funciones,
    String? estado,
    DateTime? proFechaInicio,
    DateTime? proFechaFin,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    BigInt? audUsuario,
    DateTime? audFecha,
    String? nombreUsuario,
  }) => TcpeConvocatoriaEntity(
    codConvocatoria: codConvocatoria ?? this.codConvocatoria,
    codArea: codArea ?? this.codArea,
    codDpto: codDpto ?? this.codDpto,
    gestion: gestion ?? this.gestion,
    esInterna: esInterna ?? this.esInterna,
    titulo: titulo ?? this.titulo,
    observacion: observacion ?? this.observacion,
    descripcion: descripcion ?? this.descripcion,
    nombrePuesto: nombrePuesto ?? this.nombrePuesto,
    competencias: competencias ?? this.competencias,
    objCargo: objCargo ?? this.objCargo,
    funciones: funciones ?? this.funciones,
    estado: estado ?? this.estado,
    proFechaInicio: proFechaInicio ?? this.proFechaInicio,
    proFechaFin: proFechaFin ?? this.proFechaFin,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    audUsuario: audUsuario ?? this.audUsuario,
    audFecha: audFecha ?? this.audFecha,
    nombreUsuario: nombreUsuario ?? this.nombreUsuario,
  );
}
