/// Una zona (`trh_zona`). [ciudad] y [personas] solo vienen en la pantalla de
/// ubicación geográfica.
class ZonaEntity {
  final int codZona;
  final int codCiudad;
  final String zona;
  final int audUsuario;
  final String ciudad;
  final int personas;

  ZonaEntity({
    required this.codZona,
    required this.codCiudad,
    required this.zona,
    required this.audUsuario,
    this.ciudad = '',
    this.personas = 0,
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
      ciudad: ciudad,
      personas: personas,
    );
  }

  factory ZonaEntity.vacio() {
    return ZonaEntity(codZona: 0, codCiudad: 0, zona: '', audUsuario: 0);
  }
}
