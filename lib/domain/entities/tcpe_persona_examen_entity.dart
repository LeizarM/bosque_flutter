/// Una persona del modo "Lista de personas": externo identificado por CI.
/// Si ya tiene usuario externo, el backend lo reutiliza; si no, lo crea.
class TcpePersonaExamenEntity {
  final String ci;
  final String nombres;
  final String apellidoPaterno;
  final String? apellidoMaterno;

  const TcpePersonaExamenEntity({
    required this.ci,
    required this.nombres,
    required this.apellidoPaterno,
    this.apellidoMaterno,
  });

  TcpePersonaExamenEntity copyWith({
    String? ci,
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
  }) => TcpePersonaExamenEntity(
    ci: ci ?? this.ci,
    nombres: nombres ?? this.nombres,
    apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
    apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
  );

  /// Mismo orden que el backend: apellidos y después nombres.
  String get nombreCompleto => [apellidoPaterno, apellidoMaterno ?? '', nombres]
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(' ');

  @override
  bool operator ==(Object other) =>
      other is TcpePersonaExamenEntity &&
      other.ci == ci &&
      other.nombres == nombres &&
      other.apellidoPaterno == apellidoPaterno &&
      other.apellidoMaterno == apellidoMaterno;

  @override
  int get hashCode => Object.hash(ci, nombres, apellidoPaterno, apellidoMaterno);
}
