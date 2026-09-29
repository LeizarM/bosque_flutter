import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/garantia_cbr_entity.dart';

/// Espeja 1:1 la tabla tcbr_garantia y el POJO GarantiaCbr del backend.
///
/// Fechas: el backend las entrega como "yyyy-MM-dd HH:mm:ss" y las recibe como
/// "yyyy-MM-dd". fechaInicio y fechaExpiracion son DATE en la base, asi que se
/// leen sin hora ([soloFecha]) para que un corrimiento de zona no las mueva
/// de dia.
class GarantiaCbrModel {
  final BigInt codGarantia;
  final String codClienteSAP;
  final double montoGarantia;
  final double montoCredito;
  final int tiempoPago;
  final DateTime? fechaInicio;
  final DateTime? fechaExpiracion;
  final double? montoGarantiaCalc;
  final String? recFirmas;
  final String? nroProtesta;
  final int audUsuario;
  final DateTime? audFecha;

  const GarantiaCbrModel({
    required this.codGarantia,
    required this.codClienteSAP,
    required this.montoGarantia,
    required this.montoCredito,
    required this.tiempoPago,
    required this.fechaInicio,
    required this.fechaExpiracion,
    required this.montoGarantiaCalc,
    required this.recFirmas,
    required this.nroProtesta,
    required this.audUsuario,
    required this.audFecha,
  });

  factory GarantiaCbrModel.fromJson(Map<String, dynamic> json) =>
      GarantiaCbrModel(
        codGarantia: BigInt.from((json['codGarantia'] as num?) ?? 0),
        codClienteSAP: (json['codClienteSAP'] ?? '').toString().trim(),
        montoGarantia: (json['montoGarantia'] as num?)?.toDouble() ?? 0,
        montoCredito: (json['montoCredito'] as num?)?.toDouble() ?? 0,
        tiempoPago: (json['tiempoPago'] as num?)?.toInt() ?? 0,
        fechaInicio: soloFecha(json['fechaInicio']),
        fechaExpiracion: soloFecha(json['fechaExpiracion']),
        montoGarantiaCalc: (json['montoGarantiaCalc'] as num?)?.toDouble(),
        recFirmas: json['recFirmas'] as String?,
        nroProtesta: json['nroProtesta'] as String?,
        audUsuario: (json['audUsuario'] as num?)?.toInt() ?? 0,
        audFecha: fechaHora(json['audFecha']),
      );

  /// El registro completo que pide `/garantias/actualizar`. audUsuario y
  /// audFecha no viajan: el backend los pone.
  Map<String, dynamic> toJson() => {
    'codGarantia': codGarantia.toInt(),
    'codClienteSAP': codClienteSAP,
    'montoGarantia': montoGarantia,
    'montoCredito': montoCredito,
    'tiempoPago': tiempoPago,
    'fechaInicio': fechaInicio == null ? null : fechaParaSql(fechaInicio!),
    'fechaExpiracion':
        fechaExpiracion == null ? null : fechaParaSql(fechaExpiracion!),
    'montoGarantiaCalc': montoGarantiaCalc,
    'recFirmas': recFirmas,
    'nroProtesta': nroProtesta,
  };

  GarantiaCbrEntity toEntity() => GarantiaCbrEntity(
    codGarantia: codGarantia,
    codClienteSAP: codClienteSAP,
    montoGarantia: montoGarantia,
    montoCredito: montoCredito,
    tiempoPago: tiempoPago,
    fechaInicio: fechaInicio,
    fechaExpiracion: fechaExpiracion,
    montoGarantiaCalc: montoGarantiaCalc,
    recFirmas: recFirmas,
    nroProtesta: nroProtesta,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory GarantiaCbrModel.fromEntity(GarantiaCbrEntity e) => GarantiaCbrModel(
    codGarantia: e.codGarantia,
    codClienteSAP: e.codClienteSAP,
    montoGarantia: e.montoGarantia,
    montoCredito: e.montoCredito,
    tiempoPago: e.tiempoPago,
    fechaInicio: e.fechaInicio,
    fechaExpiracion: e.fechaExpiracion,
    montoGarantiaCalc: e.montoGarantiaCalc,
    recFirmas: e.recFirmas,
    nroProtesta: e.nroProtesta,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );
}
