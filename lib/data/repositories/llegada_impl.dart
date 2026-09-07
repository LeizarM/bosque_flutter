// Destino final: lib/data/repositories/llegada_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/llegada_model.dart';
import 'package:bosque_flutter/domain/entities/llegada_entity.dart';
import 'package:bosque_flutter/domain/repositories/llegada_repository.dart';

class LlegadaImpl extends BaseApiRepository implements LlegadaRepository {
  @override
  Future<List<LlegadaEntity>> obtener() async {
    final modelos = await postAndReturnList<LlegadaModel>(
      endpoint: AppConstants.tarObtenerLlegada,
      fromJson: (json) => LlegadaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(LlegadaEntity item) async {
    final model = LlegadaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarLlegada,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la llegada.',
    );
  }

  @override
  Future<void> eliminar(int idRp, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarLlegada,
      data: {'idRp': idRp, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la llegada.',
    );
  }
}
