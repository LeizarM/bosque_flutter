import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/garantia_cbr_model.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';

/// GarantiaDto del backend: los campos de la tabla mas los calculados.
///
/// Es de SOLO LECTURA: no tiene toJson. Lo que se edita y vuelve al backend es
/// la garantia de la tabla, via [GarantiaCbrModel].
class GarantiaVistaModel {
  final GarantiaCbrModel garantia;
  final String datoCliente;
  final String datoEstado;
  final int? diasParaVencer;
  final double creditLine;
  final double balance;
  final bool traspasada;
  final int cantDetalles;
  final String? tiposGarantia;
  final DateTime? fechaRegistro;
  final String? observacionRegistro;
  final String? realizoEmp;

  const GarantiaVistaModel({
    required this.garantia,
    required this.datoCliente,
    required this.datoEstado,
    required this.diasParaVencer,
    required this.creditLine,
    required this.balance,
    required this.traspasada,
    required this.cantDetalles,
    required this.tiposGarantia,
    required this.fechaRegistro,
    required this.observacionRegistro,
    required this.realizoEmp,
  });

  factory GarantiaVistaModel.fromJson(Map<String, dynamic> json) =>
      GarantiaVistaModel(
        garantia: GarantiaCbrModel.fromJson(json),
        datoCliente: (json['datoCliente'] ?? '').toString().trim(),
        datoEstado: (json['datoEstado'] ?? '').toString().trim().toUpperCase(),
        diasParaVencer: (json['diasParaVencer'] as num?)?.toInt(),
        creditLine: (json['creditLine'] as num?)?.toDouble() ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        traspasada: ((json['traspasada'] as num?)?.toInt() ?? 0) == 1,
        cantDetalles: (json['cantDetalles'] as num?)?.toInt() ?? 0,
        tiposGarantia: json['tiposGarantia'] as String?,
        fechaRegistro: fechaHora(json['fechaRegistro']),
        observacionRegistro: json['observacionRegistro'] as String?,
        realizoEmp: (json['realizoEmp'] as String?)?.trim(),
      );

  GarantiaVistaEntity toEntity() => GarantiaVistaEntity(
    garantia: garantia.toEntity(),
    datoCliente: datoCliente,
    datoEstado: datoEstado,
    diasParaVencer: diasParaVencer,
    creditLine: creditLine,
    balance: balance,
    traspasada: traspasada,
    cantDetalles: cantDetalles,
    tiposGarantia: tiposGarantia,
    fechaRegistro: fechaRegistro,
    observacionRegistro: observacionRegistro,
    realizoEmp: realizoEmp,
  );
}
