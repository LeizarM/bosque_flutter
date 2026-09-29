import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';

/// GarantiaResumenClienteDto del backend. Solo lectura.
class GarantiaResumenClienteModel {
  final String codClienteSAP;
  final String datoCliente;
  final int cantGarantias;
  final int cantVigentes;
  final double montoGarantia;
  final double montoCredito;
  final DateTime? proximoVencimiento;
  final int? diasParaVencer;
  final double creditLine;
  final double balance;

  const GarantiaResumenClienteModel({
    required this.codClienteSAP,
    required this.datoCliente,
    required this.cantGarantias,
    required this.cantVigentes,
    required this.montoGarantia,
    required this.montoCredito,
    required this.proximoVencimiento,
    required this.diasParaVencer,
    required this.creditLine,
    required this.balance,
  });

  factory GarantiaResumenClienteModel.fromJson(Map<String, dynamic> json) =>
      GarantiaResumenClienteModel(
        codClienteSAP: (json['codClienteSAP'] ?? '').toString().trim(),
        datoCliente: (json['datoCliente'] ?? '').toString().trim(),
        cantGarantias: (json['cantGarantias'] as num?)?.toInt() ?? 0,
        cantVigentes: (json['cantVigentes'] as num?)?.toInt() ?? 0,
        montoGarantia: (json['montoGarantia'] as num?)?.toDouble() ?? 0,
        montoCredito: (json['montoCredito'] as num?)?.toDouble() ?? 0,
        proximoVencimiento: soloFecha(json['proximoVencimiento']),
        diasParaVencer: (json['diasParaVencer'] as num?)?.toInt(),
        creditLine: (json['creditLine'] as num?)?.toDouble() ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
      );

  GarantiaResumenClienteEntity toEntity() => GarantiaResumenClienteEntity(
    codClienteSAP: codClienteSAP,
    datoCliente: datoCliente,
    cantGarantias: cantGarantias,
    cantVigentes: cantVigentes,
    montoGarantia: montoGarantia,
    montoCredito: montoCredito,
    proximoVencimiento: proximoVencimiento,
    diasParaVencer: diasParaVencer,
    creditLine: creditLine,
    balance: balance,
  );
}
