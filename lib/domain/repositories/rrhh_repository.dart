import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';

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
}
