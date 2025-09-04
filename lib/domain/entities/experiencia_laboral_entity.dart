class ExperienciaLaboralEntity {
  final int codExperienciaLaboral;
  final int codEmpleado;
  final String nombreEmpresa;
  final String cargo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String nroReferencia;
  final int audUsuario;
  ExperienciaLaboralEntity({
    required this.codExperienciaLaboral,
    required this.codEmpleado,
    required this.nombreEmpresa,
    required this.cargo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.nroReferencia,
    required this.audUsuario,
  });
  Map<String, dynamic> toJson() {
    return {
      'codExperienciaLaboral': codExperienciaLaboral,
      'codEmpleado': codEmpleado,
      'nombreEmpresa': nombreEmpresa,
      'cargo': cargo,
      'descripcion': descripcion,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'nroReferencia': nroReferencia,
      'audUsuario': audUsuario,
    };
  }
  // Método copyWith
  ExperienciaLaboralEntity copyWith({
    int? codExperienciaLaboral,
    int? codEmpleado,
    String? nombreEmpresa,
    String? cargo,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? nroReferencia,
    int? audUsuario,
  }) {
    return ExperienciaLaboralEntity(
      codExperienciaLaboral: codExperienciaLaboral ?? this.codExperienciaLaboral,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      cargo: cargo ?? this.cargo,
      descripcion: descripcion ?? this.descripcion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      nroReferencia: nroReferencia ?? this.nroReferencia,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}