// Destino final: lib/domain/entities/monto_caja_chica_x_suc_entity.dart
class MontoCajaChicaXSucEntity {
  final int idCS;
  final int? codSucursal;
  final double? montoIng;
  final int audUsuario;
  final DateTime? audFecha;

  MontoCajaChicaXSucEntity({
    required this.idCS,
    this.codSucursal,
    this.montoIng,
    required this.audUsuario,
    this.audFecha,
  });

  MontoCajaChicaXSucEntity copyWith({
    int? idCS,
    int? codSucursal,
    double? montoIng,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return MontoCajaChicaXSucEntity(
      idCS: idCS ?? this.idCS,
      codSucursal: codSucursal ?? this.codSucursal,
      montoIng: montoIng ?? this.montoIng,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
