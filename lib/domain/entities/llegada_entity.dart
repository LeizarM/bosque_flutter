// Destino final: lib/domain/entities/llegada_entity.dart
class LlegadaEntity {
  final int idRp;
  final int? idTarRuti;
  final DateTime? fecha;
  final DateTime? horallegada;
  final String? persona;
  final String? cliente;
  final String? moneda;
  final double? importe;
  final String? destino;
  final String? tipo;
  final String? obs;
  final int? idBitTarRuti;
  final int? fueVerificado;
  final int? codEmpVerificado;
  final int? codSucursal;
  final int audUsuario;
  final DateTime? audFecha;

  LlegadaEntity({
    required this.idRp,
    this.idTarRuti,
    this.fecha,
    this.horallegada,
    this.persona,
    this.cliente,
    this.moneda,
    this.importe,
    this.destino,
    this.tipo,
    this.obs,
    this.idBitTarRuti,
    this.fueVerificado,
    this.codEmpVerificado,
    this.codSucursal,
    required this.audUsuario,
    this.audFecha,
  });

  LlegadaEntity copyWith({
    int? idRp,
    int? idTarRuti,
    DateTime? fecha,
    DateTime? horallegada,
    String? persona,
    String? cliente,
    String? moneda,
    double? importe,
    String? destino,
    String? tipo,
    String? obs,
    int? idBitTarRuti,
    int? fueVerificado,
    int? codEmpVerificado,
    int? codSucursal,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return LlegadaEntity(
      idRp: idRp ?? this.idRp,
      idTarRuti: idTarRuti ?? this.idTarRuti,
      fecha: fecha ?? this.fecha,
      horallegada: horallegada ?? this.horallegada,
      persona: persona ?? this.persona,
      cliente: cliente ?? this.cliente,
      moneda: moneda ?? this.moneda,
      importe: importe ?? this.importe,
      destino: destino ?? this.destino,
      tipo: tipo ?? this.tipo,
      obs: obs ?? this.obs,
      idBitTarRuti: idBitTarRuti ?? this.idBitTarRuti,
      fueVerificado: fueVerificado ?? this.fueVerificado,
      codEmpVerificado: codEmpVerificado ?? this.codEmpVerificado,
      codSucursal: codSucursal ?? this.codSucursal,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
