import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/asignacion_funcion_model.dart';
import 'package:bosque_flutter/data/models/funcion_modulo_model.dart';
import 'package:bosque_flutter/data/models/opcion_model.dart';
import 'package:bosque_flutter/data/models/resultado_escritura_model.dart';
import 'package:bosque_flutter/domain/entities/asignacion_funcion_entity.dart';
import 'package:bosque_flutter/domain/entities/funcion_modulo_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/repositories/funciones_modulo_repository.dart';

/// Las escrituras devuelven el texto que redactó el procedimiento.
mixin _Escritura on BaseApiRepository {
  Future<ResultadoEscrituraEntity> escribir(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final m = await postAndReturnFullResponse<ResultadoEscrituraModel>(
      endpoint: endpoint,
      data: data,
      fromJson: ResultadoEscrituraModel.fromJson,
    );
    return m.toEntity();
  }

  Future<List<OpcionEntity>> opciones(
    String endpoint, [
    Map<String, dynamic> data = const {},
  ]) async {
    final m = await postAndReturnList<OpcionModel>(
      endpoint: endpoint,
      data: data,
      fromJson: OpcionModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  Future<List<FuncionModuloEntity>> funcionesDe(String endpoint) async {
    final m = await postAndReturnList<FuncionModuloModel>(
      endpoint: endpoint,
      data: const {'id': 0},
      fromJson: FuncionModuloModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }
}

class FuncionesModuloImpl extends BaseApiRepository
    with _Escritura
    implements FuncionesModuloRepository {
  @override
  Future<List<OpcionEntity>> modulos() =>
      opciones(AppConstants.funcionesModuloModulos);

  @override
  Future<List<FuncionModuloEntity>> listar() =>
      funcionesDe(AppConstants.funcionesModuloListar);

  @override
  Future<ResultadoEscrituraEntity> registrar(FuncionModuloEntity f) => escribir(
    AppConstants.funcionesModuloRegistrar,
    FuncionModuloModel.fromEntity(f).toJson(),
  );

  @override
  Future<ResultadoEscrituraEntity> eliminar(BigInt codFuncMod) => escribir(
    AppConstants.funcionesModuloEliminar,
    {'id': codFuncMod.toInt()},
  );
}

class AsignacionFuncionesImpl extends BaseApiRepository
    with _Escritura
    implements AsignacionFuncionesRepository {
  @override
  Future<List<AsignacionFuncionEntity>> listar() async {
    final m = await postAndReturnList<AsignacionFuncionModel>(
      endpoint: AppConstants.asignacionFuncionesListar,
      fromJson: AsignacionFuncionModel.fromJson,
    );
    return m.map((x) => x.toEntity()).toList();
  }

  @override
  Future<List<OpcionEntity>> modulos() =>
      opciones(AppConstants.asignacionFuncionesModulos);

  @override
  Future<List<FuncionModuloEntity>> funciones() =>
      funcionesDe(AppConstants.asignacionFuncionesFunciones);

  @override
  Future<List<OpcionEntity>> sucursales() =>
      opciones(AppConstants.asignacionFuncionesSucursales);

  @override
  Future<List<OpcionEntity>> empleados(int codSucursal) => opciones(
    AppConstants.asignacionFuncionesEmpleados,
    {'id': codSucursal},
  );

  @override
  Future<ResultadoEscrituraEntity> registrar(AsignacionFuncionEntity a) =>
      escribir(
        AppConstants.asignacionFuncionesRegistrar,
        AsignacionFuncionModel.fromEntity(a).toJson(),
      );
}
