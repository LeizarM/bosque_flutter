/// Una ciudad (`trh_ciudad`). [pais], [zonas] y [sucursales] solo vienen en la
/// pantalla de ubicación geográfica.
class CiudadEntity {
  final int codCiudad;
  final int codPais;
  final String ciudad;
  final int audUsuario;
  final String pais;
  final int zonas;
  final int sucursales;

  CiudadEntity({
    required this.codCiudad,
    required this.codPais,
    required this.ciudad,
    required this.audUsuario,
    this.pais = '',
    this.zonas = 0,
    this.sucursales = 0,
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
      pais: pais,
      zonas: zonas,
      sucursales: sucursales,
    );
  }

  factory CiudadEntity.vacio() {
    return CiudadEntity(codCiudad: 0, codPais: 0, ciudad: '', audUsuario: 0);
  }
}
