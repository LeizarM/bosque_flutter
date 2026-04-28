class AreaEntity {
  int codArea;
  int codEmpresa;
  String nombreArea;
  String descripcion;
  int estado;
  int audUsuario;
  AreaEntity({
    required this.codArea,
    required this.codEmpresa,
    required this.nombreArea,
    required this.descripcion,
    required this.estado,
    required this.audUsuario,
  });

  AreaEntity copyWith({
    int? codArea,
    int? codEmpresa,
    String? nombreArea,
    String? descripcion,
    int? estado,
    int? audUsuario,
  }) => AreaEntity(
    codArea: codArea ?? this.codArea,
    codEmpresa: codEmpresa ?? this.codEmpresa,
    nombreArea: nombreArea ?? this.nombreArea,
    descripcion: descripcion ?? this.descripcion,
    estado: estado ?? this.estado,
    audUsuario: audUsuario ?? this.audUsuario,
  );
}
