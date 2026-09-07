// Destino final: lib/data/repositories/coche_llegadas_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/coche_llegadas_model.dart';
import 'package:bosque_flutter/domain/entities/coche_llegadas_entity.dart';
import 'package:bosque_flutter/domain/repositories/coche_llegadas_repository.dart';

class CocheLlegadasImpl extends BaseApiRepository
    implements CocheLlegadasRepository {
  @override
  Future<List<CocheLlegadasEntity>> obtener() async {
    final modelos = await postAndReturnList<CocheLlegadasModel>(
      endpoint: AppConstants.tarObtenerCocheLlegadas,
      fromJson: (json) => CocheLlegadasModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(CocheLlegadasEntity item) async {
    final model = CocheLlegadasModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarCocheLlegadas,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la llegada de coche.',
    );
  }

  @override
  Future<void> eliminar(int idCo, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarCocheLlegadas,
      data: {'idCo': idCo, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la llegada de coche.',
    );
  }
}
