// Destino final: lib/data/repositories/caja_chica_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/caja_chica_model.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:bosque_flutter/domain/repositories/caja_chica_repository.dart';

class CajaChicaImpl extends BaseApiRepository implements CajaChicaRepository {
  @override
  Future<List<CajaChicaEntity>> obtener() async {
    final modelos = await postAndReturnList<CajaChicaModel>(
      endpoint: AppConstants.tarObtenerCajaChica,
      fromJson: (json) => CajaChicaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(CajaChicaEntity item) async {
    final model = CajaChicaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarCajaChica,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la caja chica.',
    );
  }

  @override
  Future<void> eliminar(int idCC, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarCajaChica,
      data: {'idCC': idCC, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la caja chica.',
    );
  }
}
