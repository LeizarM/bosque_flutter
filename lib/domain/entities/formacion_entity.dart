class FormacionEntity {
  final int codFormacion;
  final int codEmpleado;
  final String descripcion;
  final int duracion;
  final String tipoDuracion;
  final String tipoFormacion;
  final DateTime fechaFormacion;
  final int audUsuario;
  FormacionEntity({
    required this.codFormacion,
    required this.codEmpleado,
    required this.descripcion,
    required this.duracion,
    required this.tipoDuracion,
    required this.tipoFormacion,
    required this.fechaFormacion,
    required this.audUsuario,
  });
  Map<String, dynamic> toJson() {
    return {
      'codFormacion': codFormacion,
      'codEmpleado': codEmpleado,
      'descripcion': descripcion,
      'duracion': duracion,
      'tipoDuracion': tipoDuracion,
      'tipoFormacion': tipoFormacion,
      'fechaFormacion': fechaFormacion.toIso8601String(),
      'audUsuario': audUsuario,
    };
  }
  // Método copyWith
  FormacionEntity copyWith({
    int? codFormacion,
    int? codEmpleado,
    String? descripcion,
    int? duracion,
    String? tipoDuracion,
    String? tipoFormacion,
    DateTime? fechaFormacion,
    int? audUsuario,
  }) {
    return FormacionEntity(
      codFormacion: codFormacion ?? this.codFormacion,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      descripcion: descripcion ?? this.descripcion,
      duracion: duracion ?? this.duracion,
      tipoDuracion: tipoDuracion ?? this.tipoDuracion,
      tipoFormacion: tipoFormacion ?? this.tipoFormacion,
      fechaFormacion: fechaFormacion ?? this.fechaFormacion,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}