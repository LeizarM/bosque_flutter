import 'package:bosque_flutter/domain/entities/sucursal_archivo_entity.dart';

class SucursalArchivoModel {
  final int codSucursal;
  final String nombre;
  final int codEmpresa;
  final String? nombreEmpresa;
  final String? ciudad;

  const SucursalArchivoModel({
    required this.codSucursal,
    required this.nombre,
    this.codEmpresa = 0,
    this.nombreEmpresa,
    this.ciudad,
  });

  factory SucursalArchivoModel.fromJson(Map<String, dynamic> json) {
    int? entero(String clave) => (json[clave] as num?)?.toInt();
    return SucursalArchivoModel(
      codSucursal: entero('codSucursal') ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      codEmpresa: entero('codEmpresa') ?? 0,
      nombreEmpresa: json['nombreEmpresa'] as String?,
      ciudad: json['ciudad'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'codSucursal': codSucursal,
    'nombre': nombre,
    'codEmpresa': codEmpresa,
    'nombreEmpresa': nombreEmpresa,
    'ciudad': ciudad,
  };

  SucursalArchivoEntity toEntity() => SucursalArchivoEntity(
    codSucursal: codSucursal,
    nombre: nombre,
    codEmpresa: codEmpresa,
    nombreEmpresa: nombreEmpresa,
    ciudad: ciudad,
  );
}
