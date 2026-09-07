// Destino final: lib/data/repositories/mov_caja_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/mov_caja_model.dart';
import 'package:bosque_flutter/domain/entities/mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/mov_caja_repository.dart';

class MovCajaImpl extends BaseApiRepository implements MovCajaRepository {
  @override
  Future<List<MovCajaEntity>> obtener() async {
    final modelos = await postAndReturnList<MovCajaModel>(
      endpoint: AppConstants.tarObtenerMovCaja,
      fromJson: (json) => MovCajaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(MovCajaEntity item) async {
    final model = MovCajaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarMovCaja,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el movimiento de caja.',
    );
  }

  @override
  Future<void> eliminar(int idMC, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarMovCaja,
      data: {'idMC': idMC, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el movimiento de caja.',
    );
  }
}
