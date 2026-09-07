// Destino final: lib/domain/entities/suc_x_mov_caja_entity.dart
class SucXMovCajaEntity {
  final int idSxMC;
  final int? codSucursal;
  final String? codigoCuentaCajaSap;
  final String? nombre;
  final String? bd;
  final int audUsuario;
  final DateTime? audFecha;

  SucXMovCajaEntity({
    required this.idSxMC,
    this.codSucursal,
    this.codigoCuentaCajaSap,
    this.nombre,
    this.bd,
    required this.audUsuario,
    this.audFecha,
  });

  SucXMovCajaEntity copyWith({
    int? idSxMC,
    int? codSucursal,
    String? codigoCuentaCajaSap,
    String? nombre,
    String? bd,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return SucXMovCajaEntity(
      idSxMC: idSxMC ?? this.idSxMC,
      codSucursal: codSucursal ?? this.codSucursal,
      codigoCuentaCajaSap: codigoCuentaCajaSap ?? this.codigoCuentaCajaSap,
      nombre: nombre ?? this.nombre,
      bd: bd ?? this.bd,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
