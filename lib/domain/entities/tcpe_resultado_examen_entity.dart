/// Un examen del lote con su estado y nota (`p_list_tcpe_Resultado` L).
class TcpeResultadoExamenEntity {
  final BigInt codExamen;
  final BigInt? codRolExamen;
  final BigInt? codUsuario;
  final String? login;
  final BigInt? codEmpleado;
  final String? nombreCompleto;
  final String? ci;
  final String? estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? fechaLimite;
  final double? resultado;
  /// `resultado >= notaAprobacion` del lote.
  final bool aprobado;
  final double? notaAprobacion;
  final int totalPreguntas;
  final int respondidas;
  final int abiertasPendientes;

  const TcpeResultadoExamenEntity({
    required this.codExamen,
    this.codRolExamen,
    this.codUsuario,
    this.login,
    this.codEmpleado,
    this.nombreCompleto,
    this.ci,
    this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.fechaLimite,
    this.resultado,
    this.aprobado = false,
    this.notaAprobacion,
    this.totalPreguntas = 0,
    this.respondidas = 0,
    this.abiertasPendientes = 0,
  });

  TcpeResultadoExamenEntity copyWith({
    BigInt? codExamen,
    BigInt? codRolExamen,
    BigInt? codUsuario,
    String? login,
    BigInt? codEmpleado,
    String? nombreCompleto,
    String? ci,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    DateTime? fechaLimite,
    double? resultado,
    bool? aprobado,
    double? notaAprobacion,
    int? totalPreguntas,
    int? respondidas,
    int? abiertasPendientes,
  }) => TcpeResultadoExamenEntity(
    codExamen: codExamen ?? this.codExamen,
    codRolExamen: codRolExamen ?? this.codRolExamen,
    codUsuario: codUsuario ?? this.codUsuario,
    login: login ?? this.login,
    codEmpleado: codEmpleado ?? this.codEmpleado,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    ci: ci ?? this.ci,
    estado: estado ?? this.estado,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    fechaLimite: fechaLimite ?? this.fechaLimite,
    resultado: resultado ?? this.resultado,
    aprobado: aprobado ?? this.aprobado,
    notaAprobacion: notaAprobacion ?? this.notaAprobacion,
    totalPreguntas: totalPreguntas ?? this.totalPreguntas,
    respondidas: respondidas ?? this.respondidas,
    abiertasPendientes: abiertasPendientes ?? this.abiertasPendientes,
  );

  bool get esEmpleado => codEmpleado != null;

  /// Aprobado o reprobado solo si ya tiene nota; null mientras no la tenga.
  bool? get aprobacion => resultado == null ? null : aprobado;
}
