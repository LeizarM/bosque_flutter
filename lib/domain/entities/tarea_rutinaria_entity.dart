// Destino final: lib/domain/entities/tarea_rutinaria_entity.dart
class TareaRutinariaEntity {
  final int idTarRuti;
  final int? idFrec;
  final int? idArea;
  final DateTime? fechaPartida;
  final int? iniFin;
  final int? idATR;
  final String descripcion;
  final int audUsuario;
  final DateTime? audFecha;

  TareaRutinariaEntity({
    required this.idTarRuti,
    this.idFrec,
    this.idArea,
    this.fechaPartida,
    this.iniFin,
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
    int? iniFin,
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
      iniFin: iniFin ?? this.iniFin,
      idATR: idATR ?? this.idATR,
      descripcion: descripcion ?? this.descripcion,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
