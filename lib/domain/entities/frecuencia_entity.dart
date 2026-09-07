// Destino final: lib/domain/entities/frecuencia_entity.dart
class FrecuenciaEntity {
  final int idFrec;
  final String? descripcion;
  final int? estado;
  final int audUsuario;
  final DateTime? audFecha;

  FrecuenciaEntity({
    required this.idFrec,
    this.descripcion,
    this.estado,
    required this.audUsuario,
    this.audFecha,
  });

  FrecuenciaEntity copyWith({
    int? idFrec,
    String? descripcion,
    int? estado,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return FrecuenciaEntity(
      idFrec: idFrec ?? this.idFrec,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
