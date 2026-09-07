// Destino final: lib/data/repositories/monto_caja_chica_x_suc_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/monto_caja_chica_x_suc_model.dart';
import 'package:bosque_flutter/domain/entities/monto_caja_chica_x_suc_entity.dart';
import 'package:bosque_flutter/domain/repositories/monto_caja_chica_x_suc_repository.dart';

class MontoCajaChicaXSucImpl extends BaseApiRepository
    implements MontoCajaChicaXSucRepository {
  @override
  Future<List<MontoCajaChicaXSucEntity>> obtener() async {
    final modelos = await postAndReturnList<MontoCajaChicaXSucModel>(
      endpoint: AppConstants.tarObtenerMontoCajaChicaXSuc,
      fromJson: (json) => MontoCajaChicaXSucModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(MontoCajaChicaXSucEntity item) async {
    final model = MontoCajaChicaXSucModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarMontoCajaChicaXSuc,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el monto de caja chica por sucursal.',
    );
  }

  @override
  Future<void> eliminar(int idCS, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarMontoCajaChicaXSuc,
      data: {'idCS': idCS, 'audUsuario': audUsuario},
      errorMessage:
          'No se pudo eliminar el monto de caja chica por sucursal.',
    );
  }
}
