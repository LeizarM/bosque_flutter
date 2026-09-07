// Destino final: lib/domain/entities/coche_llegadas_entity.dart
class CocheLlegadasEntity {
  final int idCo;
  final int? idTarRuti;
  final int? idCoche;
  final int? idBitTarRuti;
  final String? descripcion;
  final DateTime? fecha;
  final int? llego;
  final String? obs;
  final int audUsuario;
  final DateTime? audFecha;

  CocheLlegadasEntity({
    required this.idCo,
    this.idTarRuti,
    this.idCoche,
    this.idBitTarRuti,
    this.descripcion,
    this.fecha,
    this.llego,
    this.obs,
    required this.audUsuario,
    this.audFecha,
  });

  CocheLlegadasEntity copyWith({
    int? idCo,
    int? idTarRuti,
    int? idCoche,
    int? idBitTarRuti,
    String? descripcion,
    DateTime? fecha,
    int? llego,
    String? obs,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return CocheLlegadasEntity(
      idCo: idCo ?? this.idCo,
      idTarRuti: idTarRuti ?? this.idTarRuti,
      idCoche: idCoche ?? this.idCoche,
      idBitTarRuti: idBitTarRuti ?? this.idBitTarRuti,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      llego: llego ?? this.llego,
      obs: obs ?? this.obs,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
