// Destino final: lib/domain/entities/vale_entity.dart
class ValeEntity {
  final int idVale;
  final int? idAC;
  final int? numVale;
  final String? nombre;
  final double? monto;
  final DateTime? fecha;
  final String? obs;
  final int? codEmpresa;
  final int audUsuario;
  final DateTime? audFecha;

  ValeEntity({
    required this.idVale,
    this.idAC,
    this.numVale,
    this.nombre,
    this.monto,
    this.fecha,
    this.obs,
    this.codEmpresa,
    required this.audUsuario,
    this.audFecha,
  });

  ValeEntity copyWith({
    int? idVale,
    int? idAC,
    int? numVale,
    String? nombre,
    double? monto,
    DateTime? fecha,
    String? obs,
    int? codEmpresa,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return ValeEntity(
      idVale: idVale ?? this.idVale,
      idAC: idAC ?? this.idAC,
      numVale: numVale ?? this.numVale,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      obs: obs ?? this.obs,
      codEmpresa: codEmpresa ?? this.codEmpresa,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
