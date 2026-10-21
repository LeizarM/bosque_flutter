import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';

/// El ABM de empresas y sucursales de la estructura organizacional (vista 12).
/// Alta si el código es 0, edición si es mayor.
abstract class EmpresasSucursalesRepository {
  Future<List<EmpresaEntity>> listarEmpresas();

  /// Todas las sucursales, con su empresa, ciudad y cargos.
  Future<List<SucursalEntity>> listarSucursales();

  /// Las ciudades para el formulario de sucursal.
  Future<List<CiudadEntity>> ciudades();

  Future<ResultadoEscrituraEntity> registrarEmpresa(EmpresaEntity empresa);
  Future<ResultadoEscrituraEntity> registrarSucursal(SucursalEntity sucursal);
  Future<ResultadoEscrituraEntity> eliminarEmpresa(int codEmpresa);
  Future<ResultadoEscrituraEntity> eliminarSucursal(int codSucursal);
}
