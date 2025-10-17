class SocioTigoEntity {
  final int codCuenta;
  final int telefono;
  final int? codEmpleado;
  final String nombreCompleto;
  final String? descripcion;
  final String periodoCobrado;
  final int audUsuario;

  SocioTigoEntity({
    required this.codCuenta,
    required this.telefono,
    required this.codEmpleado,
    required this.nombreCompleto,
    required this.descripcion,
    required this.periodoCobrado,
    required this.audUsuario,
  });
  Map<String, dynamic> toJson() => {
        "codCuenta": codCuenta,
        "telefono": telefono,
        "codEmpleado": codEmpleado,
        "nombreCompleto": nombreCompleto,
        "descripcion": descripcion,
        "periodoCobrado": periodoCobrado,
        "audUsuario": audUsuario,
      };

  //metodo copyWith
  SocioTigoEntity copyWith({
    int? codCuenta,
    int? telefono,
    int? codEmpleado,
    String? nombreCompleto,
    String? descripcion,
    String? periodoCobrado,
    
    int? audUsuario,
  }) {
    return SocioTigoEntity(
      codCuenta: codCuenta ?? this.codCuenta,
      telefono: telefono ?? this.telefono,
      codEmpleado: codEmpleado ?? this.codEmpleado,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      descripcion: descripcion ?? this.descripcion,
      periodoCobrado: periodoCobrado ?? this.periodoCobrado,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}