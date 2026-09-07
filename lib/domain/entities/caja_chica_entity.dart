// Destino final: lib/domain/entities/caja_chica_entity.dart
class CajaChicaEntity {
  final int idCC;
  final int? idBitTarRuti;
  final String? persona;
  final double? montoIng;
  final double? montoEg;
  final double? saldo;
  final int? numFactura;
  final int? numVale;
  final String? moneda;
  final String? descripcion;
  final int? codEmpDestino;
  final DateTime? fecha;
  final int? codSucursal;
  final int? lote;
  final int audUsuario;
  final DateTime? audFecha;

  CajaChicaEntity({
    required this.idCC,
    this.idBitTarRuti,
    this.persona,
    this.montoIng,
    this.montoEg,
    this.saldo,
    this.numFactura,
    this.numVale,
    this.moneda,
    this.descripcion,
    this.codEmpDestino,
    this.fecha,
    this.codSucursal,
    this.lote,
    required this.audUsuario,
    this.audFecha,
  });

  CajaChicaEntity copyWith({
    int? idCC,
    int? idBitTarRuti,
    String? persona,
    double? montoIng,
    double? montoEg,
    double? saldo,
    int? numFactura,
    int? numVale,
    String? moneda,
    String? descripcion,
    int? codEmpDestino,
    DateTime? fecha,
    int? codSucursal,
    int? lote,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return CajaChicaEntity(
      idCC: idCC ?? this.idCC,
      idBitTarRuti: idBitTarRuti ?? this.idBitTarRuti,
      persona: persona ?? this.persona,
      montoIng: montoIng ?? this.montoIng,
      montoEg: montoEg ?? this.montoEg,
      saldo: saldo ?? this.saldo,
      numFactura: numFactura ?? this.numFactura,
      numVale: numVale ?? this.numVale,
      moneda: moneda ?? this.moneda,
      descripcion: descripcion ?? this.descripcion,
      codEmpDestino: codEmpDestino ?? this.codEmpDestino,
      fecha: fecha ?? this.fecha,
      codSucursal: codSucursal ?? this.codSucursal,
      lote: lote ?? this.lote,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
