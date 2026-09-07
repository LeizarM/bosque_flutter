// Destino final: lib/data/repositories/frecuencia_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/frecuencia_model.dart';
import 'package:bosque_flutter/domain/entities/frecuencia_entity.dart';
import 'package:bosque_flutter/domain/repositories/frecuencia_repository.dart';

class FrecuenciaImpl extends BaseApiRepository implements FrecuenciaRepository {
  @override
  Future<List<FrecuenciaEntity>> obtener() async {
    final modelos = await postAndReturnList<FrecuenciaModel>(
      endpoint: AppConstants.tarObtenerFrecuencia,
      fromJson: (json) => FrecuenciaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(FrecuenciaEntity item) async {
    final model = FrecuenciaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarFrecuencia,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la frecuencia.',
    );
  }

  @override
  Future<void> eliminar(int idFrec, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarFrecuencia,
      data: {'idFrec': idFrec, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la frecuencia.',
    );
  }
}
