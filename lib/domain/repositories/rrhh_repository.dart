import 'package:bosque_flutter/data/models/area_model.dart';
import 'package:bosque_flutter/domain/entities/area_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/entities/cargo_sucursal_entity.dart';

abstract class RRHHRepository {
  //Registrar Empresa
  Future<bool> registerEmpresa(EmpresaEntity mb);

  //Para Listar Empresas
  Future<List<EmpresaEntity>> lstEmpresas();

  //Para Listar Cargos por Empresa
  Future<List<CargoEntity>> lstCargos(int codEmpresa);

  //Para Listar Sucursales por Empresa
  Future<List<SucursalEntity>> lstSucursales(int codEmpresa);

  //Para listar los cargos por empresa pero con detalles adicionales
  Future<List<CargoEntity>> lstCargosXEmpresa(int codEmpresa);

  //Para Actualizar o registrar un cargo
  Future<bool> registrarCargo(CargoEntity cargo);

  //Para listar las sucursales que pertenece un cargo
  Future<List<CargoSucursalEntity>> lstSucursalesXCargo(int codCargo);

  //Para registrar asignación de cargo a sucursal
  Future<bool> registrarCargoSucursal(CargoSucursalEntity cargoSucursal);

  //Para eliminar asignación de cargo a sucursal
  Future<bool> eliminarCargoSucursal(int codCargoSucursal);

  //Para obtener los empleados asignados a un cargo
  Future<List<CargoEntity>> obtenerEmpleadosXCargo(int codCargo);
  //obtener areas por empresa
  Future<List<AreaEntity>> obtenerArea(int codEmpresa);
  //registrar area por empresa
  Future<AreaResponse> registrarArea(AreaEntity area);
}
