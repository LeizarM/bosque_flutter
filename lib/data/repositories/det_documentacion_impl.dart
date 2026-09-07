// Destino final: lib/data/repositories/det_documentacion_impl.dart
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/data/models/det_documentacion_model.dart';
import 'package:bosque_flutter/domain/entities/det_documentacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/det_documentacion_repository.dart';

class DetDocumentacionImpl extends BaseApiRepository
    implements DetDocumentacionRepository {
  @override
  Future<List<DetDocumentacionEntity>> obtener() async {
    final modelos = await postAndReturnList<DetDocumentacionModel>(
      endpoint: AppConstants.tarObtenerDetDocumentacion,
      fromJson: (json) => DetDocumentacionModel.fromJson(json),
    );
    return modelos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<BigInt> registrar(DetDocumentacionEntity item) async {
    final model = DetDocumentacionModel.fromEntity(item);
    return postAndReturnId(
      endpoint: AppConstants.tarRegistrarDetDocumentacion,
      data: model.toJson(),
      errorMessage: 'No se pudo guardar el detalle de documentación.',
    );
  }

  @override
  Future<void> eliminar(int idDetDoc, int audUsuario) async {
    await postAndReturnId(
      endpoint: AppConstants.tarEliminarDetDocumentacion,
      data: {'idDetDoc': idDetDoc, 'audUsuario': audUsuario},
      errorMessage: 'No se pudo eliminar el detalle de documentación.',
    );
  }
}
