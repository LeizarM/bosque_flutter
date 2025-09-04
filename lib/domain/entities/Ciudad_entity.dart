class CiudadEntity {
  final int codCiudad;
  final int codPais;
  final String ciudad;
  final int audUsuario;

  CiudadEntity({
    required this.codCiudad,
    required this.codPais,
    required this.ciudad,
    required this.audUsuario,
  });
//metodo tojson
  Map<String, dynamic> toJson() {
    return {
      'codCiudad': codCiudad,
      'codPais': codPais,
      'ciudad': ciudad,
      'audUsuario': audUsuario,
    };
  }
  //metodo copyWith
  CiudadEntity copyWith({
    int? codCiudad,
    int? codPais,
    String? ciudad,
    int? audUsuario,
  }) {
    return CiudadEntity(
      codCiudad: codCiudad ?? this.codCiudad,
      codPais: codPais ?? this.codPais,
      ciudad: ciudad ?? this.ciudad,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}
