// Destino final: lib/data/repositories/coche_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/coche_model.dart';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';
import 'package:bosque_flutter/domain/repositories/coche_repository.dart';

class CocheImpl extends BaseApiRepository implements CocheRepository {
  @override
  Future<List<CocheEntity>> obtener() async {
    final modelos = await postAndReturnList<CocheModel>(
      endpoint: AppConstants.tarObtenerCoche,
      fromJson: (json) => CocheModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(CocheEntity item) async {
    final model = CocheModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarCoche,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el coche.',
    );
  }

  @override
  Future<void> eliminar(int idCoche, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarCoche,
      data: {'idCoche': idCoche, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el coche.',
    );
  }
}
