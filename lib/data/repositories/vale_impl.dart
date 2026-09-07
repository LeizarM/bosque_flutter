// Destino final: lib/data/repositories/vale_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/vale_model.dart';
import 'package:bosque_flutter/domain/entities/vale_entity.dart';
import 'package:bosque_flutter/domain/repositories/vale_repository.dart';

class ValeImpl extends BaseApiRepository implements ValeRepository {
  @override
  Future<List<ValeEntity>> obtener() async {
    final modelos = await postAndReturnList<ValeModel>(
      endpoint: AppConstants.tarObtenerVale,
      fromJson: (json) => ValeModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(ValeEntity item) async {
    final model = ValeModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarVale,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el vale.',
    );
  }

  @override
  Future<void> eliminar(int idVale, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarVale,
      data: {'idVale': idVale, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el vale.',
    );
  }
}
