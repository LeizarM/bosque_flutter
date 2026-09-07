import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/dia_no_laborable_model.dart';
import 'package:bosque_flutter/data/models/sucursal_seleccion_model.dart';
import 'package:bosque_flutter/domain/entities/dia_no_laborable_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_seleccion_entity.dart';
import 'package:bosque_flutter/domain/repositories/dias_no_laborables_repository.dart';

class DiasNoLaborablesImpl extends BaseApiRepository
    implements DiasNoLaborablesRepository {
  @override
  Future<BigInt> registrarDiaNoLaborable(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.diasNoLabRegistrar,
        data: payload,
        errorMessage: 'Error al registrar el dia no laborable',
      );

  @override
  Future<BigInt> eliminarDiaNoLaborable(Map<String, dynamic> payload) =>
      postAndReturnId(
        endpoint: AppConstants.diasNoLabEliminar,
        data: payload,
        errorMessage: 'Error al eliminar el dia no laborable',
      );

  @override
  Future<List<DiaNoLaborableEntity>> obtenerDiasNoLaborables({
    int gestion = 0,
  }) async {
    final modelos = await postAndReturnList<DiaNoLaborableModel>(
      endpoint: AppConstants.diasNoLabObtener,
      data: {'gestion': gestion},
      fromJson: (json) => DiaNoLaborableModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SucursalSeleccionEntity>> obtenerSucursalesDiaNoLaborable(
    BigInt idDiaNoLaborable,
  ) async {
    final modelos = await postAndReturnList<SucursalSeleccionModel>(
      endpoint: AppConstants.diasNoLabObtenerSucursales,
      data: {'idDiaNoLaborable': idDiaNoLaborable.toInt()},
      fromJson: (json) => SucursalSeleccionModel.fromJson(json),
    );
    return modelos.map((m) => m.toEntity()).toList();
  }
}
