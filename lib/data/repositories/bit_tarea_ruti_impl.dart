// Destino final: lib/data/repositories/bit_tarea_ruti_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/bit_tarea_ruti_model.dart';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:bosque_flutter/domain/repositories/bit_tarea_ruti_repository.dart';

class BitTareaRutiImpl extends BaseApiRepository
    implements BitTareaRutiRepository {
  @override
  Future<List<BitTareaRutiEntity>> obtener() async {
    final modelos = await postAndReturnList<BitTareaRutiModel>(
      endpoint: AppConstants.tarObtenerBitTareaRuti,
      fromJson: (json) => BitTareaRutiModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(BitTareaRutiEntity item) async {
    final model = BitTareaRutiModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarBitTareaRuti,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la bitácora de tarea rutinaria.',
    );
  }

  @override
  Future<void> eliminar(int idBitTarea, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarBitTareaRuti,
      data: {'idBitTarea': idBitTarea, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la bitácora de tarea rutinaria.',
    );
  }
}
