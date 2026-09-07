// Destino final: lib/domain/entities/tar_ru_x_cargo_entity.dart
class TarRuXCargoEntity {
  final int idTarXCargo;
  final int? idTarRuti;
  final int? codCargo;
  final int? estado;
  final int audUsuario;
  final DateTime? audFecha;
  final int? codCargoSucursal;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  TarRuXCargoEntity({
    required this.idTarXCargo,
    this.idTarRuti,
    this.codCargo,
    this.estado,
    required this.audUsuario,
    this.audFecha,
    this.codCargoSucursal,
    this.fechaInicio,
    this.fechaFin,
  });

  TarRuXCargoEntity copyWith({
    int? idTarXCargo,
    int? idTarRuti,
    int? codCargo,
    int? estado,
    int? audUsuario,
    DateTime? audFecha,
    int? codCargoSucursal,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    return TarRuXCargoEntity(
      idTarXCargo: idTarXCargo ?? this.idTarXCargo,
      idTarRuti: idTarRuti ?? this.idTarRuti,
      codCargo: codCargo ?? this.codCargo,
      estado: estado ?? this.estado,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
      codCargoSucursal: codCargoSucursal ?? this.codCargoSucursal,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
    );
  }
}
