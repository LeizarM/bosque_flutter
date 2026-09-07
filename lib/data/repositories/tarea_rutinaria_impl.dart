// Destino final: lib/data/repositories/tarea_rutinaria_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/tarea_rutinaria_model.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/tarea_rutinaria_repository.dart';

class TareaRutinariaImpl extends BaseApiRepository
    implements TareaRutinariaRepository {
  @override
  Future<List<TareaRutinariaEntity>> obtener() async {
    final modelos = await postAndReturnList<TareaRutinariaModel>(
      endpoint: AppConstants.tarObtenerTareaRutinaria,
      fromJson: (json) => TareaRutinariaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(TareaRutinariaEntity item) async {
    final model = TareaRutinariaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarTareaRutinaria,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la tarea rutinaria.',
    );
  }

  @override
  Future<void> eliminar(int idTarRuti, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarTareaRutinaria,
      data: {'idTarRuti': idTarRuti, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la tarea rutinaria.',
    );
  }
}
