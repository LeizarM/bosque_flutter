// Destino final: lib/data/repositories/coches_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/coche_del_dia_model.dart';
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';
import 'package:bosque_flutter/domain/repositories/coches_repository.dart';

class CochesImpl extends BaseApiRepository implements CochesRepository {
  @override
  Future<List<CocheDelDiaEntity>> listarDelDia({
    required int idTarRuti,
    required int idBitTarea,
  }) async {
    final modelos = await postAndReturnList<CocheDelDiaModel>(
      endpoint: AppConstants.tarCochesListarDelDia,
      data: {
        'idTarRuti': idTarRuti,
        'idBitTarea': idBitTarea,
      },
      fromJson: (json) => CocheDelDiaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<bool> marcarLlegada({
    required int idCo,
    required int llego,
    String? obs,
  }) async {
    final resultado = await postAndReturnId(
      endpoint: AppConstants.tarCochesMarcarLlegada,
      data: {'idCo': idCo, 'llego': llego, 'obs': obs},
      errorMessage: 'No se pudo registrar la llegada del coche.',
    );
    return resultado == BigInt.one;
  }
}
