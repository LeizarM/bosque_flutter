// Destino final: lib/domain/entities/coche_del_dia_entity.dart

/// Una fila de la lista "coches del día" de una ocurrencia puntual de tarea
/// rutinaria (idATR=6). `llego` es `null` mientras no se marcó, 0=NO, 1=SI —
/// distinto del legacy, que usaba 0 como valor por defecto Y como "NO" a la
/// vez.
class CocheDelDiaEntity {
  final int idCo;
  final int? idTarRuti;
  final int? idBitTarRuti;
  final int? idCoche;
  final String? descripcion;
  final DateTime? fecha;
  final int? llego;
  final String? obs;
  final String? marca;
  final String? clase;
  final String? placa;
  final String? color;
  final int? anio;

  const CocheDelDiaEntity({
    required this.idCo,
    this.idTarRuti,
    this.idBitTarRuti,
    this.idCoche,
    this.descripcion,
    this.fecha,
    this.llego,
    this.obs,
    this.marca,
    this.clase,
    this.placa,
    this.color,
    this.anio,
  });

  bool get yaMarcado => llego != null;

  CocheDelDiaEntity copyWith({int? llego, String? obs}) {
    return CocheDelDiaEntity(
      idCo: idCo,
      idTarRuti: idTarRuti,
      idBitTarRuti: idBitTarRuti,
      idCoche: idCoche,
      descripcion: descripcion,
      fecha: fecha,
      llego: llego ?? this.llego,
      obs: obs ?? this.obs,
      marca: marca,
      clase: clase,
      placa: placa,
      color: color,
      anio: anio,
    );
  }
}
