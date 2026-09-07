// Destino final: lib/domain/entities/det_arqueo_caja_sucursales_entity.dart
class DetArqueoCajaSucursalesEntity {
  final int idDetAS;
  final int? idAC;
  final int? idCorte;
  final int? cantidad;
  final double? subTotal;
  final int audUsuario;
  final DateTime? audFecha;

  DetArqueoCajaSucursalesEntity({
    required this.idDetAS,
    this.idAC,
    this.idCorte,
    this.cantidad,
    this.subTotal,
    required this.audUsuario,
    this.audFecha,
  });

  DetArqueoCajaSucursalesEntity copyWith({
    int? idDetAS,
    int? idAC,
    int? idCorte,
    int? cantidad,
    double? subTotal,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return DetArqueoCajaSucursalesEntity(
      idDetAS: idDetAS ?? this.idDetAS,
      idAC: idAC ?? this.idAC,
      idCorte: idCorte ?? this.idCorte,
      cantidad: cantidad ?? this.cantidad,
      subTotal: subTotal ?? this.subTotal,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
