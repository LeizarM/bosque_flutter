class ChoferEntity {
  final int codEmpleado;
  final String nombreCompleto;
  final String cargo;
  
  ChoferEntity({
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.cargo,
  });
  
  // Constructor de copia para hacer inmutable la entidad
  ChoferEntity copyWith({
    int? codEmpleado,
    String? nombreCompleto,
    String? cargo,
  }) {
    return ChoferEntity(
      codEmpleado: codEmpleado ?? this.codEmpleado,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      cargo: cargo ?? this.cargo,
    );
  }
  
  // Factory constructor para crear desde EntregaEntity
  factory ChoferEntity.fromEntregaEntity(dynamic entregaEntity) {
    return ChoferEntity(
      codEmpleado: entregaEntity.codEmpleado,
      nombreCompleto: entregaEntity.nombreCompleto ?? 'Sin nombre',
      cargo: entregaEntity.cargo ?? 'Sin cargo',
    );
  }
}