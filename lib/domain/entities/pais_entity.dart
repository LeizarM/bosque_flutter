/// Un país (`trh_pais`). [ciudades] y [personas] solo vienen en la pantalla de
/// ubicación geográfica: cuántas ciudades tiene y cuántas personas lo tienen
/// como nacionalidad.
class PaisEntity {
  final int codPais;
  final String pais;
  final int audUsuario;
  final int ciudades;
  final int personas;

  PaisEntity({
    required this.codPais,
    required this.pais,
    required this.audUsuario,
    this.ciudades = 0,
    this.personas = 0,
  });
  // Método toJson
  Map<String, dynamic> toJson() {
    return {'codPais': codPais, 'pais': pais, 'audUsuario': audUsuario};
  }

  // Método copyWith
  PaisEntity copyWith({int? codPais, String? pais, int? audUsuario}) {
    return PaisEntity(
      codPais: codPais ?? this.codPais,
      pais: pais ?? this.pais,
      audUsuario: audUsuario ?? this.audUsuario,
      ciudades: ciudades,
      personas: personas,
    );
  }

  factory PaisEntity.vacio() {
    return PaisEntity(codPais: 0, pais: '', audUsuario: 0);
  }
}
