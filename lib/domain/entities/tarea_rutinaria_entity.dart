// Destino final: lib/domain/entities/tarea_rutinaria_entity.dart
class TareaRutinariaEntity {
  final int idTarRuti;
  final int? idFrec;
  final int? idArea;
  final DateTime? fechaPartida;
  final int? IniFin;
  final int? idATR;
  final String descripcion;
  final int audUsuario;
  final DateTime? audFecha;

  TareaRutinariaEntity({
    required this.idTarRuti,
    this.idFrec,
    this.idArea,
    this.fechaPartida,
    this.IniFin,
    this.idATR,
    required this.descripcion,
    required this.audUsuario,
    this.audFecha,
  });

  TareaRutinariaEntity copyWith({
    int? idTarRuti,
    int? idFrec,
    int? idArea,
    DateTime? fechaPartida,
    int? IniFin,
    int? idATR,
    String? descripcion,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return TareaRutinariaEntity(
      idTarRuti: idTarRuti ?? this.idTarRuti,
      idFrec: idFrec ?? this.idFrec,
      idArea: idArea ?? this.idArea,
      fechaPartida: fechaPartida ?? this.fechaPartida,
      IniFin: IniFin ?? this.IniFin,
      idATR: idATR ?? this.idATR,
      descripcion: descripcion ?? this.descripcion,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
