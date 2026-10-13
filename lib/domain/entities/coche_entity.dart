// Destino final: lib/domain/entities/coche_entity.dart
class CocheEntity {
  /// Estado de un vehículo en uso. Cualquier otro valor es inactivo.
  static const int activo = 1;
  static const int inactivo = 0;

  final int idCoche;
  final String? marca;
  final String? clase;
  final String? placa;
  final int? anio;
  final String? color;
  final int? codSucursal;

  /// Solo lectura: el nombre de la sucursal, que llega del JOIN del listado.
  final String? nombreSucursal;
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
    this.nombreSucursal,
    this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  bool get esActivo => estado == activo;

  CocheEntity copyWith({
    int? idCoche,
    String? marca,
    String? clase,
    String? placa,
    int? anio,
    String? color,
    int? codSucursal,
    String? nombreSucursal,
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
      nombreSucursal: nombreSucursal ?? this.nombreSucursal,
      estado: estado ?? this.estado,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
