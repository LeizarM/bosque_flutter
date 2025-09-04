class ZonaEntity {
  final int codZona;
  final int codCiudad;
  final String zona;
  final int audUsuario;

  ZonaEntity({
    required this.codZona,
    required this.codCiudad,
    required this.zona,
    required this.audUsuario,
  });
  //metodo toJson
  Map<String, dynamic> toJson() {
    return {
      'codZona': codZona,
      'codCiudad': codCiudad,
      'zona': zona,
      'audUsuario': audUsuario,
    };
  }
  //metodo copywith
  ZonaEntity copyWith({
    int? codZona,
    int? codCiudad,
    String? zona,
    int? audUsuario,
  }) {
    return ZonaEntity(
      codZona: codZona ?? this.codZona,
      codCiudad: codCiudad ?? this.codCiudad,
      zona: zona ?? this.zona,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}