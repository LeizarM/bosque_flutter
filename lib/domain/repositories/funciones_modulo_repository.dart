import 'package:bosque_flutter/domain/entities/asignacion_funcion_entity.dart';
import 'package:bosque_flutter/domain/entities/funcion_modulo_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';

/// Funciones por módulo (vista 57). Alta si `codFuncMod` es 0.
abstract class FuncionesModuloRepository {
  Future<List<OpcionEntity>> modulos();
  Future<List<FuncionModuloEntity>> listar();
  Future<ResultadoEscrituraEntity> registrar(FuncionModuloEntity funcion);
  Future<ResultadoEscrituraEntity> eliminar(BigInt codFuncMod);
}

/// Asignación de funciones a empleados (vista 56). Cada pantalla pide sus
/// combos a su propio endpoint porque el servidor exige esa pantalla.
abstract class AsignacionFuncionesRepository {
  Future<List<AsignacionFuncionEntity>> listar();
  Future<List<OpcionEntity>> modulos();
  Future<List<FuncionModuloEntity>> funciones();
  Future<List<OpcionEntity>> sucursales();
  Future<List<OpcionEntity>> empleados(int codSucursal);

  /// Alta si `codAsignacion` es 0; si es mayor solo cambia el estado.
  Future<ResultadoEscrituraEntity> registrar(AsignacionFuncionEntity a);
}
