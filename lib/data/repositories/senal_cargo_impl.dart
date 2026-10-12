// Destino final: lib/data/repositories/senal_cargo_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/senal_cargo_model.dart';
import 'package:bosque_flutter/domain/entities/senal_cargo_entity.dart';
import 'package:bosque_flutter/domain/repositories/senal_cargo_repository.dart';

class SenalCargoImpl extends BaseApiRepository implements SenalCargoRepository {
  static String _mensaje(Map<String, dynamic> j) =>
      (j['message'] as String?) ?? 'Listo.';

  @override
  Future<List<SenalCargo>> lista({bool verCalladas = false}) =>
      postAndReturnList(
        endpoint: AppConstants.tarSenalesCargoLista,
        data: {'verCalladas': verCalladas},
        fromJson: SenalCargoModel.senal,
      );

  @override
  Future<List<SenalCargo>> deMiEquipo() => postAndReturnList(
    endpoint: AppConstants.tarSenalesCargoDeMiEquipo,
    data: const <String, dynamic>{},
    fromJson: SenalCargoModel.senal,
  );

  @override
  Future<String> estaBien(SenalCargo senal, {String? obs}) =>
      postAndReturnFullResponse(
        endpoint: AppConstants.tarSenalesCargoEstaBien,
        data: {
          'codEmpleado': senal.codEmpleado,
          'idTarRuti': senal.idTarRuti,
          'obs': (obs == null || obs.trim().isEmpty) ? null : obs.trim(),
        },
        fromJson: _mensaje,
        errorMessage: 'No se pudo guardar.',
      );

  @override
  Future<String> volverAMostrar(SenalCargo senal) => postAndReturnFullResponse(
    endpoint: AppConstants.tarSenalesCargoVolverAMostrar,
    data: {'idSC': senal.idSC, 'codEmpleado': senal.codEmpleado},
    fromJson: _mensaje,
    errorMessage: 'No se pudo guardar.',
  );
}
