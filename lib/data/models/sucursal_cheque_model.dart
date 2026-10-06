import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';

/// SucursalChequeDto del backend: `{ codSucursal, nombre }`.
class SucursalChequeModel {
  final int codSucursal;
  final String nombre;

  const SucursalChequeModel({required this.codSucursal, required this.nombre});

  factory SucursalChequeModel.fromJson(Map<String, dynamic> json) =>
      SucursalChequeModel(
        codSucursal: (json['codSucursal'] as num?)?.toInt() ?? 0,
        nombre: (json['nombre'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
    'codSucursal': codSucursal,
    'nombre': nombre,
  };

  SucursalChequeEntity toEntity() =>
      SucursalChequeEntity(codSucursal: codSucursal, nombre: nombre);

  factory SucursalChequeModel.fromEntity(SucursalChequeEntity e) =>
      SucursalChequeModel(codSucursal: e.codSucursal, nombre: e.nombre);
}
