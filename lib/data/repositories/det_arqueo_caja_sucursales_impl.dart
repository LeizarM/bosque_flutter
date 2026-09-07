// Destino final: lib/data/repositories/det_arqueo_caja_sucursales_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/det_arqueo_caja_sucursales_model.dart';
import 'package:bosque_flutter/domain/entities/det_arqueo_caja_sucursales_entity.dart';
import 'package:bosque_flutter/domain/repositories/det_arqueo_caja_sucursales_repository.dart';

class DetArqueoCajaSucursalesImpl extends BaseApiRepository
    implements DetArqueoCajaSucursalesRepository {
  @override
  Future<List<DetArqueoCajaSucursalesEntity>> obtener() async {
    final modelos = await postAndReturnList<DetArqueoCajaSucursalesModel>(
      endpoint: AppConstants.tarObtenerDetArqueoCajaSucursales,
      fromJson: (json) => DetArqueoCajaSucursalesModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(DetArqueoCajaSucursalesEntity item) async {
    final model = DetArqueoCajaSucursalesModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarDetArqueoCajaSucursales,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el detalle de arqueo de caja de sucursales.',
    );
  }

  @override
  Future<void> eliminar(int idDetAS, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarDetArqueoCajaSucursales,
      data: {'idDetAS': idDetAS, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el detalle de arqueo de caja de sucursales.',
    );
  }
}
