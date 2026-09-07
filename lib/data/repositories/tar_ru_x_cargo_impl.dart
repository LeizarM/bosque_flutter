// Destino final: lib/data/repositories/tar_ru_x_cargo_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/tar_ru_x_cargo_model.dart';
import 'package:bosque_flutter/domain/entities/tar_ru_x_cargo_entity.dart';
import 'package:bosque_flutter/domain/repositories/tar_ru_x_cargo_repository.dart';

class TarRuXCargoImpl extends BaseApiRepository
    implements TarRuXCargoRepository {
  @override
  Future<List<TarRuXCargoEntity>> obtener() async {
    final modelos = await postAndReturnList<TarRuXCargoModel>(
      endpoint: AppConstants.tarObtenerTarRuXCargo,
      fromJson: (json) => TarRuXCargoModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(TarRuXCargoEntity item) async {
    final model = TarRuXCargoModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarTarRuXCargo,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la asignación de cargo a tarea rutinaria.',
    );
  }

  @override
  Future<void> eliminar(int idTarXCargo, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarTarRuXCargo,
      data: {'idTarXCargo': idTarXCargo, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la asignación de cargo a tarea rutinaria.',
    );
  }
}
