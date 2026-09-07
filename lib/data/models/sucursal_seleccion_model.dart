import 'package:bosque_flutter/domain/entities/sucursal_seleccion_entity.dart';

class SucursalSeleccionModel {
  BigInt codSucursal;
  String nombreSucEmpresa;
  int seleccionado;

  SucursalSeleccionModel({
    required this.codSucursal,
    required this.nombreSucEmpresa,
    required this.seleccionado,
  });

  factory SucursalSeleccionModel.fromJson(Map<String, dynamic> json) =>
      SucursalSeleccionModel(
        codSucursal: json['codSucursal'] != null
            ? BigInt.from(json['codSucursal'])
            : BigInt.zero,
        nombreSucEmpresa: json['nombreSucEmpresa'] ?? '',
        seleccionado: json['seleccionado'] ?? 0,
      );

  SucursalSeleccionEntity toEntity() => SucursalSeleccionEntity(
    codSucursal: codSucursal,
    nombreSucEmpresa: nombreSucEmpresa,
    seleccionado: seleccionado == 1,
  );
}
