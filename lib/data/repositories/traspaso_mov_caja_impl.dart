// Destino final: lib/data/repositories/traspaso_mov_caja_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/traspaso_mov_caja_model.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/traspaso_mov_caja_repository.dart';

class TraspasoMovCajaImpl extends BaseApiRepository
    implements TraspasoMovCajaRepository {
  @override
  Future<List<TraspasoMovCajaEntity>> obtener() async {
    final modelos = await postAndReturnList<TraspasoMovCajaModel>(
      endpoint: AppConstants.tarObtenerTraspasoMovCaja,
      fromJson: (json) => TraspasoMovCajaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(TraspasoMovCajaEntity item) async {
    final model = TraspasoMovCajaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarTraspasoMovCaja,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el traspaso de movimiento de caja.',
    );
  }

  @override
  Future<void> eliminar(int idTrasp, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarTraspasoMovCaja,
      data: {'idTrasp': idTrasp, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el traspaso de movimiento de caja.',
    );
  }
}
