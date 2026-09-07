// Destino final: lib/domain/entities/mov_caja_entity.dart
class MovCajaEntity {
  final int idMC;
  final int? idAC;
  final int? idSxMC;
  final int? codSucursal;
  final double? montoBs;
  final int audUsuario;
  final DateTime? audFecha;

  MovCajaEntity({
    required this.idMC,
    this.idAC,
    this.idSxMC,
    this.codSucursal,
    this.montoBs,
    required this.audUsuario,
    this.audFecha,
  });

  MovCajaEntity copyWith({
    int? idMC,
    int? idAC,
    int? idSxMC,
    int? codSucursal,
    double? montoBs,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return MovCajaEntity(
      idMC: idMC ?? this.idMC,
      idAC: idAC ?? this.idAC,
      idSxMC: idSxMC ?? this.idSxMC,
      codSucursal: codSucursal ?? this.codSucursal,
      montoBs: montoBs ?? this.montoBs,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
