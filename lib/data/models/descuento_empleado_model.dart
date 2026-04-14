import 'package:bosque_flutter/domain/entities/descuento_empleado_entity.dart';

class DescuentoEmpleadoModel {
  final int codEmpleado;
  final String descripcion;
  final String moneda;
  final double montoTotal;
  final int totalCuotas;
  final String periodo;
  final String tipoDescuento;
  final String estadoDescuento;
  final int primeraCuotaMes;
  final int ultimaCuotaMes;
  final double montoDescuento;
  final double saldoRestante;

  const DescuentoEmpleadoModel({
    required this.codEmpleado,
    required this.descripcion,
    required this.moneda,
    required this.montoTotal,
    required this.totalCuotas,
    required this.periodo,
    required this.tipoDescuento,
    required this.estadoDescuento,
    required this.primeraCuotaMes,
    required this.ultimaCuotaMes,
    required this.montoDescuento,
    required this.saldoRestante,
  });

  factory DescuentoEmpleadoModel.fromJson(Map<String, dynamic> json) =>
      DescuentoEmpleadoModel(
        codEmpleado: json['codEmpleado'] ?? 0,
        descripcion: json['descripcion'] ?? '',
        moneda: json['moneda'] ?? 'Bs',
        montoTotal: (json['montoTotal'] ?? 0).toDouble(),
        totalCuotas: json['totalCuotas'] ?? 0,
        periodo: json['periodo'] ?? '',
        tipoDescuento: json['tipoDescuento'] ?? '',
        estadoDescuento: json['estadoDescuento'] ?? '',
        primeraCuotaMes: json['primeraCuotaMes'] ?? 0,
        ultimaCuotaMes: json['ultimaCuotaMes'] ?? 0,
        montoDescuento: (json['montoDescuento'] ?? 0).toDouble(),
        saldoRestante: (json['saldoRestante'] ?? 0).toDouble(),
      );

  DescuentoEmpleadoEntity toEntity() => DescuentoEmpleadoEntity(
    codEmpleado: codEmpleado,
    descripcion: descripcion,
    moneda: moneda,
    montoTotal: montoTotal,
    totalCuotas: totalCuotas,
    periodo: periodo,
    tipoDescuento: tipoDescuento,
    estadoDescuento: estadoDescuento,
    primeraCuotaMes: primeraCuotaMes,
    ultimaCuotaMes: ultimaCuotaMes,
    montoDescuento: montoDescuento,
    saldoRestante: saldoRestante,
  );
}
