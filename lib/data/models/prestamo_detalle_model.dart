import 'package:bosque_flutter/domain/entities/prestamo_detalle_entity.dart';

class PrestamoDetalleModel extends PrestamoDetalleEntity {
  PrestamoDetalleModel({
    required super.codPrestDetalle,
    required super.codPrestamo,
    super.tipoPago,
    super.datoPago,
    super.detalle,
    super.observacion,
    super.postergado,
    super.estadoCuota,
    super.numeroCuota,
    required super.montoPago,
    required super.debe,
    required super.haber,
    required super.saldo,
    super.fechaPago,
    super.audUsuario,
    super.audFecha,
  });

  factory PrestamoDetalleModel.fromJson(Map<String, dynamic> json) {
    return PrestamoDetalleModel(
      codPrestDetalle: json['codPrestDetalle'] ?? 0,
      codPrestamo: json['codPrestamo'] ?? 0,
      tipoPago: json['tipoPago'],
      datoPago: json['datoPago'],
      detalle: json['detalle'],
      observacion: json['observacion'],
      postergado: json['postergado'],
      estadoCuota: json['estadoCuota'],
      numeroCuota: json['numeroCuota'],
      montoPago: (json['montoPago'] ?? 0.0).toDouble(),
      debe: (json['debe'] ?? 0.0).toDouble(),
      haber: (json['haber'] ?? 0.0).toDouble(),
      saldo: (json['saldo'] ?? 0.0).toDouble(),
      fechaPago:
          json['fechaPago'] != null
              ? DateTime.tryParse(json['fechaPago'].toString())
              : null,
      audUsuario: json['audUsuario'],
      audFecha:
          json['audFecha'] != null
              ? DateTime.tryParse(json['audFecha'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codPrestDetalle': codPrestDetalle,
      'codPrestamo': codPrestamo,
      'tipoPago': tipoPago,
      'datoPago': datoPago,
      'detalle': detalle,
      'observacion': observacion,
      'postergado': postergado,
      'estadoCuota': estadoCuota,
      'numeroCuota': numeroCuota,
      'montoPago': montoPago,
      'debe': debe,
      'haber': haber,
      'saldo': saldo,
      'fechaPago': fechaPago?.toIso8601String(),
      'audUsuario': audUsuario,
      'audFecha': audFecha?.toIso8601String(),
    };
  }
}
