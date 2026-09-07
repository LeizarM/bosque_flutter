// Destino final: lib/domain/entities/coche_entity.dart
class CocheEntity {
  final int idCoche;
  final String? marca;
  final String? clase;
  final String? placa;
  final int? anio;
  final String? color;
  final int? codSucursal;
  final int? estado;
  final int audUsuario;
  final DateTime? audFecha;

  CocheEntity({
    required this.idCoche,
    this.marca,
    this.clase,
    this.placa,
    this.anio,
    this.color,
    this.codSucursal,
    this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  CocheEntity copyWith({
    int? idCoche,
    String? marca,
    String? clase,
    String? placa,
    int? anio,
    String? color,
    int? codSucursal,
    int? estado,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return CocheEntity(
      idCoche: idCoche ?? this.idCoche,
      marca: marca ?? this.marca,
      clase: clase ?? this.clase,
      placa: placa ?? this.placa,
      anio: anio ?? this.anio,
      color: color ?? this.color,
      codSucursal: codSucursal ?? this.codSucursal,
      estado: estado ?? this.estado,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
