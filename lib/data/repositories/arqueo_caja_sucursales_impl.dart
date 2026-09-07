// Destino final: lib/data/repositories/arqueo_caja_sucursales_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/arqueo_caja_sucursales_model.dart';
import 'package:bosque_flutter/domain/entities/arqueo_caja_sucursales_entity.dart';
import 'package:bosque_flutter/domain/repositories/arqueo_caja_sucursales_repository.dart';

class ArqueoCajaSucursalesImpl extends BaseApiRepository
    implements ArqueoCajaSucursalesRepository {
  @override
  Future<List<ArqueoCajaSucursalesEntity>> obtener() async {
    final modelos = await postAndReturnList<ArqueoCajaSucursalesModel>(
      endpoint: AppConstants.tarObtenerArqueoCajaSucursales,
      fromJson: (json) => ArqueoCajaSucursalesModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(ArqueoCajaSucursalesEntity item) async {
    final model = ArqueoCajaSucursalesModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarArqueoCajaSucursales,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el arqueo de caja de sucursales.',
    );
  }

  @override
  Future<void> eliminar(int idAC, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarArqueoCajaSucursales,
      data: {'idAC': idAC, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el arqueo de caja de sucursales.',
    );
  }
}
