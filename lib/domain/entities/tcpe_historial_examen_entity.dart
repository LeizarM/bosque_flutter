/// Un examen rendido por una persona, buscada por CI (`p_list_tcpe_Resultado` H).
class TcpeHistorialExamenEntity {
  final BigInt codExamen;
  final BigInt? codRolExamen;
  final String? tituloLote;
  final String? nombreClasificacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? estado;
  final double? resultado;
  final String? login;
  final String? nombreCompleto;
  final String? ci;
  final double? notaAprobacion;
  final bool? aprobado;

  const TcpeHistorialExamenEntity({
    required this.codExamen,
    this.codRolExamen,
    this.tituloLote,
    this.nombreClasificacion,
    this.fechaInicio,
    this.fechaFin,
    this.estado,
    this.resultado,
    this.login,
    this.nombreCompleto,
    this.ci,
    this.notaAprobacion,
    this.aprobado,
  });

  TcpeHistorialExamenEntity copyWith({
    BigInt? codExamen,
    BigInt? codRolExamen,
    String? tituloLote,
    String? nombreClasificacion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    double? resultado,
    String? login,
    String? nombreCompleto,
    String? ci,
    double? notaAprobacion,
    bool? aprobado,
  }) => TcpeHistorialExamenEntity(
    codExamen: codExamen ?? this.codExamen,
    codRolExamen: codRolExamen ?? this.codRolExamen,
    tituloLote: tituloLote ?? this.tituloLote,
    nombreClasificacion: nombreClasificacion ?? this.nombreClasificacion,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    estado: estado ?? this.estado,
    resultado: resultado ?? this.resultado,
    login: login ?? this.login,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    ci: ci ?? this.ci,
    notaAprobacion: notaAprobacion ?? this.notaAprobacion,
    aprobado: aprobado ?? this.aprobado,
  );
}
