import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';

/// Espeja 1:1 la tabla tcbr_cbrDetalle y el POJO CbrDetalle del backend.
class CbrDetalleModel {
  final BigInt codDetalle;
  final BigInt codGarantia;
  final DateTime? fecha;
  final String tipoGarantia;
  final String? detalle;
  final double? montoGarantiaParc;
  final int audUsuario;
  final DateTime? audFecha;

  const CbrDetalleModel({
    required this.codDetalle,
    required this.codGarantia,
    required this.fecha,
    required this.tipoGarantia,
    required this.detalle,
    required this.montoGarantiaParc,
    required this.audUsuario,
    required this.audFecha,
  });

  factory CbrDetalleModel.fromJson(Map<String, dynamic> json) =>
      CbrDetalleModel(
        codDetalle: BigInt.from((json['codDetalle'] as num?) ?? 0),
        codGarantia: BigInt.from((json['codGarantia'] as num?) ?? 0),
        fecha: fechaHora(json['fecha']),
        tipoGarantia: (json['tipoGarantia'] ?? '').toString().trim(),
        detalle: json['detalle'] as String?,
        montoGarantiaParc: (json['montoGarantiaParc'] as num?)?.toDouble(),
        audUsuario: (json['audUsuario'] as num?)?.toInt() ?? 0,
        audFecha: fechaHora(json['audFecha']),
      );

  /// Lo que acepta `/garantias/detalle/registrar` y cada detalle de
  /// `/garantias/registrar`. La fecha no viaja: la pone el servidor.
  Map<String, dynamic> toJson() => {
    'codDetalle': codDetalle.toInt(),
    'codGarantia': codGarantia.toInt(),
    'tipoGarantia': tipoGarantia,
    'detalle': detalle,
    'montoGarantiaParc': montoGarantiaParc,
  };

  CbrDetalleEntity toEntity() => CbrDetalleEntity(
    codDetalle: codDetalle,
    codGarantia: codGarantia,
    fecha: fecha,
    tipoGarantia: tipoGarantia,
    detalle: detalle,
    montoGarantiaParc: montoGarantiaParc,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory CbrDetalleModel.fromEntity(CbrDetalleEntity e) => CbrDetalleModel(
    codDetalle: e.codDetalle,
    codGarantia: e.codGarantia,
    fecha: e.fecha,
    tipoGarantia: e.tipoGarantia,
    detalle: e.detalle,
    montoGarantiaParc: e.montoGarantiaParc,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );
}
