import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';

/// Entity para la relación entre Cargo y Sucursal
class CargoSucursalEntity {
  final int codCargoSucursal;
  final int codSucursal;
  final int codCargo;
  final int audUsuario;
  final String datoCargo;
  final SucursalEntity? sucursal;
  final CargoEntity? cargo;

  CargoSucursalEntity({
    required this.codCargoSucursal,
    required this.codSucursal,
    required this.codCargo,
    required this.audUsuario,
    required this.datoCargo,
    this.sucursal,
    this.cargo,
  });
}
