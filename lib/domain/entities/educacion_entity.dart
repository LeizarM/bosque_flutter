class EducacionEntity {
  final int codEducacion;
  final int codEmpleado;
  final String tipoEducacion;
  final String descripcion;
  final DateTime fecha;
  final int audUsuario;
  EducacionEntity({
    required this.codEducacion,
    required this.codEmpleado,
    required this.tipoEducacion,
    required this.descripcion,
    required this.fecha,
    required this.audUsuario,
  });
Map<String, dynamic> toJson() {
    return {
      'codEducacion': codEducacion,
      'codEmpleado': codEmpleado,
      'tipoEducacion': tipoEducacion,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'audUsuario': audUsuario,
    };
  }
  //metodo copyWith
  EducacionEntity copyWith({
    int? codEducacion,
    int? codEmpleado,
    String? tipoEducacion,
    String? descripcion,
    DateTime? fecha,
    int? audUsuario,
  }) {
    return EducacionEntity(
      codEducacion: codEducacion ?? this.codEducacion,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      tipoEducacion: tipoEducacion ?? this.tipoEducacion,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
  //metodo empty
  // ✅ Constructor nombrado empty()
  factory EducacionEntity.empty() {
    return EducacionEntity(
      codEducacion: 0,
      codEmpleado: 0,
      tipoEducacion: '',
      descripcion: '',
      fecha: DateTime.now(),
      audUsuario: 0,
    );
  }

}
  