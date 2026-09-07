// Destino final: lib/data/repositories/corte_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/corte_model.dart';
import 'package:bosque_flutter/domain/entities/corte_entity.dart';
import 'package:bosque_flutter/domain/repositories/corte_repository.dart';

class CorteImpl extends BaseApiRepository implements CorteRepository {
  @override
  Future<List<CorteEntity>> obtener() async {
    final modelos = await postAndReturnList<CorteModel>(
      endpoint: AppConstants.tarObtenerCorte,
      fromJson: (json) => CorteModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(CorteEntity item) async {
    final model = CorteModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarCorte,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el corte.',
    );
  }

  @override
  Future<void> eliminar(int idCorte, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarCorte,
      data: {'idCorte': idCorte, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el corte.',
    );
  }
}
