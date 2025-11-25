import 'package:bosque_flutter/data/models/cargo_model.dart';
import 'package:bosque_flutter/data/models/sucursal_model.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';

/// Model para la relación entre Cargo y Sucursal
class CargoSucursalModel {
  final int codCargoSucursal;
  final int codSucursal;
  final int codCargo;
  final int audUsuario;
  final String datoCargo;
  final SucursalModel? sucursal;
  final CargoModel? cargo;

  CargoSucursalModel({
    required this.codCargoSucursal,
    required this.codSucursal,
    required this.codCargo,
    required this.audUsuario,
    required this.datoCargo,
    this.sucursal,
    this.cargo,
  });

  /// Desde JSON
  factory CargoSucursalModel.fromJson(Map<String, dynamic> json) {
    return CargoSucursalModel(
      codCargoSucursal: _parseToInt(json['codCargoSucursal']),
      codSucursal: _parseToInt(json['codSucursal']),
      codCargo: _parseToInt(json['codCargo']),
      audUsuario: _parseToInt(json['audUsuario']),
      datoCargo: json['datoCargo']?.toString() ?? '',
      sucursal:
          json['sucursal'] != null
              ? SucursalModel.fromJson(json['sucursal'])
              : null,
      cargo: json['cargo'] != null ? CargoModel.fromJson(json['cargo']) : null,
    );
  }

  /// Helper para parsear valores int desde String o int
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Hacia JSON
  Map<String, dynamic> toJson() {
    return {
      'codCargoSucursal': codCargoSucursal,
      'codSucursal': codSucursal,
      'codCargo': codCargo,
      'audUsuario': audUsuario,
      'datoCargo': datoCargo,
      'sucursal': sucursal?.toJson(),
      'cargo': cargo?.toJson(),
    };
  }

  /// Convertir Model → Entity
  CargoSucursalEntity toEntity() {
    return CargoSucursalEntity(
      codCargoSucursal: codCargoSucursal,
      codSucursal: codSucursal,
      codCargo: codCargo,
      audUsuario: audUsuario,
      datoCargo: datoCargo,
      sucursal: sucursal?.toEntity(),
      cargo: cargo?.toEntity(),
    );
  }

  /// Convertir Entity → Model
  factory CargoSucursalModel.fromEntity(CargoSucursalEntity entity) {
    return CargoSucursalModel(
      codCargoSucursal: entity.codCargoSucursal,
      codSucursal: entity.codSucursal,
      codCargo: entity.codCargo,
      audUsuario: entity.audUsuario,
      datoCargo: entity.datoCargo,
      sucursal:
          entity.sucursal != null
              ? SucursalModel.fromEntity(entity.sucursal!)
              : null,
      cargo: entity.cargo != null ? CargoModel.fromEntity(entity.cargo!) : null,
    );
  }
}
