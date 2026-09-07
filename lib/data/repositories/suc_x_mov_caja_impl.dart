// Destino final: lib/data/repositories/suc_x_mov_caja_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/suc_x_mov_caja_model.dart';
import 'package:bosque_flutter/domain/entities/suc_x_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/suc_x_mov_caja_repository.dart';

class SucXMovCajaImpl extends BaseApiRepository
    implements SucXMovCajaRepository {
  @override
  Future<List<SucXMovCajaEntity>> obtener() async {
    final modelos = await postAndReturnList<SucXMovCajaModel>(
      endpoint: AppConstants.tarObtenerSucXMovCaja,
      fromJson: (json) => SucXMovCajaModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(SucXMovCajaEntity item) async {
    final model = SucXMovCajaModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarSucXMovCaja,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar la sucursal por movimiento de caja.',
    );
  }

  @override
  Future<void> eliminar(int idSxMC, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarSucXMovCaja,
      data: {'idSxMC': idSxMC, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar la sucursal por movimiento de caja.',
    );
  }
}
