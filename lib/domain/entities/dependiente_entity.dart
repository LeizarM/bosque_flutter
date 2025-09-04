class DependienteEntity {
  final int codDependiente;
  final int codPersona;
  final int codEmpleado;
  final String parentesco;
  final String esActivo;
  final int audUsuario;
  final String nombreCompleto;
  final dynamic descripcion;
  final int edad;
  DependienteEntity({
    required this.codDependiente,
    required this.codPersona,
    required this.codEmpleado,
    required this.parentesco,
    required this.esActivo,
    required this.audUsuario,
    required this.nombreCompleto,
    required this.descripcion,
    required this.edad,
  });
   Map<String, dynamic> toJson() {
    return {
      'codEmpleado': codEmpleado,
      'codDependiente': codDependiente,
      'codPersona': codPersona,
      'parentesco': parentesco,
      'esActivo': esActivo,
      'nombreCompleto': nombreCompleto,
      'audUsuario': audUsuario, 
    };
  }
  
  //metodo copywith
  DependienteEntity copyWith({
    int? codDependiente,
    int? codPersona,
    int? codEmpleado,
    String? parentesco,
    String? esActivo,
    int? audUsuario,
    String? nombreCompleto,
    dynamic descripcion,
    int? edad,
  }) {
    return DependienteEntity(
      codDependiente: codDependiente ?? this.codDependiente,
      codPersona: codPersona ?? this.codPersona,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      parentesco: parentesco ?? this.parentesco,
      esActivo: esActivo ?? this.esActivo,
      audUsuario: audUsuario ?? this.audUsuario,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      descripcion: descripcion ?? this.descripcion,
      edad: edad ?? this.edad,
    );
  }
  
}