// Destino final: lib/data/repositories/accion_tarea_rutinaria_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/accion_tarea_rutinaria_model.dart';
import 'package:bosque_flutter/domain/entities/accion_tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/accion_tarea_rutinaria_repository.dart';

class AccionTareaRutinariaImpl extends BaseApiRepository
    implements AccionTareaRutinariaRepository {
  @override
  Future<List<AccionTareaRutinariaEntity>> obtener() async {
    final modelos = await postAndReturnList<AccionTareaRutinariaModel>(
      endpoint: AppConstants.tarObtenerAccionTareaRutinaria,
      fromJson: (json) => AccionTareaRutinariaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(AccionTareaRutinariaEntity item) async {
    final model = AccionTareaRutinariaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarAccionTareaRutinaria,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la acción de tarea rutinaria.',
    );
  }

  @override
  Future<void> eliminar(int idATR, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarAccionTareaRutinaria,
      data: {'idATR': idATR, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la acción de tarea rutinaria.',
    );
  }
}
