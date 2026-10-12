// Destino final: lib/domain/entities/coche_del_dia_entity.dart

/// Una fila de la lista de autos del día de la sucursal (archivo SQL 96: una
/// sola lista por sucursal y día, compartida). `llego` es `null` mientras no
/// se marcó, 0=NO, 1=SI — distinto del legacy, que usaba 0 como valor por
/// defecto Y como "NO" a la vez.
class CocheDelDiaEntity {
  final int idCo;
  final int? idTarRuti;
  final int? idCoche;
  final String? descripcion;

  /// Cuándo se marcó. Null mientras nadie lo marque.
  final DateTime? fecha;
  final int? llego;
  final String? obs;
  final String? marca;
  final String? clase;
  final String? placa;
  final String? color;
  final int? anio;

  /// Quién lo marcó: la lista es de todos los de la sucursal.
  final String? quienMarco;

  const CocheDelDiaEntity({
    required this.idCo,
    this.idTarRuti,
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
    this.quienMarco,
  });

  bool get yaMarcado => llego != null;

  CocheDelDiaEntity copyWith({int? llego, String? obs}) {
    return CocheDelDiaEntity(
      idCo: idCo,
      idTarRuti: idTarRuti,
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
      quienMarco: quienMarco,
    );
  }
}
