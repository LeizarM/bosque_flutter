// Destino final: lib/domain/entities/traspaso_mov_caja_entity.dart
class TraspasoMovCajaEntity {
  final int idTrasp;
  final String? bd;
  final DateTime? fecha;
  final String? account;
  final String? contraAct;
  final String? acctName;
  final String? tipoTransaccion;
  final double? dolares;
  final double? bs;
  final int? fueVerificado;
  final int? idBitTarRuti;
  final int audUsuario;
  final DateTime? audFecha;

  TraspasoMovCajaEntity({
    required this.idTrasp,
    this.bd,
    this.fecha,
    this.account,
    this.contraAct,
    this.acctName,
    this.tipoTransaccion,
    this.dolares,
    this.bs,
    this.fueVerificado,
    this.idBitTarRuti,
    required this.audUsuario,
    this.audFecha,
  });

  TraspasoMovCajaEntity copyWith({
    int? idTrasp,
    String? bd,
    DateTime? fecha,
    String? account,
    String? contraAct,
    String? acctName,
    String? tipoTransaccion,
    double? dolares,
    double? bs,
    int? fueVerificado,
    int? idBitTarRuti,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return TraspasoMovCajaEntity(
      idTrasp: idTrasp ?? this.idTrasp,
      bd: bd ?? this.bd,
      fecha: fecha ?? this.fecha,
      account: account ?? this.account,
      contraAct: contraAct ?? this.contraAct,
      acctName: acctName ?? this.acctName,
      tipoTransaccion: tipoTransaccion ?? this.tipoTransaccion,
      dolares: dolares ?? this.dolares,
      bs: bs ?? this.bs,
      fueVerificado: fueVerificado ?? this.fueVerificado,
      idBitTarRuti: idBitTarRuti ?? this.idBitTarRuti,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
