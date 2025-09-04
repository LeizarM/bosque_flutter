class PaisEntity {
  final int codPais;
  final String pais;
  final int audUsuario;

  PaisEntity({
    required this.codPais,
    required this.pais,
    required this.audUsuario,
  });
  // Método toJson
  Map<String, dynamic> toJson() {
    return {
      'codPais': codPais,
      'pais': pais,
      'audUsuario': audUsuario,
    };
  }
  // Método copyWith
  PaisEntity copyWith({
    int? codPais,
    String? pais,
    int? audUsuario,
  }) {
    return PaisEntity(
      codPais: codPais ?? this.codPais,
      pais: pais ?? this.pais,
      audUsuario: audUsuario ?? this.audUsuario,
    );
  }
}